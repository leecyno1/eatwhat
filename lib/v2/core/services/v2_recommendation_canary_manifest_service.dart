import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:cryptography/cryptography.dart';
import 'package:eatwhat_app/v2/core/data/models/recommendation_canary_manifest.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

typedef V2CanaryManifestSignatureVerifier = Future<bool> Function({
  required List<int> message,
  required List<int> signature,
  required List<int> publicKey,
});
typedef V2CanaryManifestStateReader = Future<String?> Function();
typedef V2CanaryManifestStateWriter = Future<bool> Function(String value);

enum RecommendationCanaryManifestIngestionState {
  acceptedForManualReview,
  trustStoreUnconfigured,
  manifestTooLarge,
  malformed,
  unknownKey,
  invalidSignature,
  wrongAudience,
  wrongEnvironment,
  issuedInFuture,
  expired,
  replayedOrStale,
  stagedStateInvalid,
  storageUnavailable,
}

class RecommendationCanaryManifestIngestionResult {
  const RecommendationCanaryManifestIngestionResult({
    required this.state,
    required this.reason,
    this.manifest,
    this.payloadDigest,
  });

  final RecommendationCanaryManifestIngestionState state;
  final String reason;
  final RecommendationCanaryManifest? manifest;
  final String? payloadDigest;

  bool get acceptedForManualReview =>
      state ==
      RecommendationCanaryManifestIngestionState.acceptedForManualReview;

  bool get authorizesCanaryActivation => false;
  bool get authorizesCanaryExpansion => false;
  bool get authorizesFullRollout => false;
}

enum RecommendationCanaryStagedManifestState {
  absent,
  staged,
  reviewed,
  expired,
  invalid,
  unavailable,
}

class RecommendationCanaryStagedManifestInspection {
  const RecommendationCanaryStagedManifestInspection({
    required this.state,
    this.manifest,
    this.acceptedAt,
    this.payloadDigest,
  });

  final RecommendationCanaryStagedManifestState state;
  final RecommendationCanaryManifest? manifest;
  final DateTime? acceptedAt;
  final String? payloadDigest;

  bool get hasPendingManualReview =>
      state == RecommendationCanaryStagedManifestState.staged;

  bool get authorizesCanaryActivation => false;
}

enum RecommendationCanaryManifestAcknowledgementState {
  acknowledged,
  alreadyAcknowledged,
  noStagedManifest,
  expired,
  tokenMismatch,
  stagedStateInvalid,
  storageUnavailable,
}

class RecommendationCanaryManifestAcknowledgementResult {
  const RecommendationCanaryManifestAcknowledgementResult({
    required this.state,
    required this.reason,
  });

  final RecommendationCanaryManifestAcknowledgementState state;
  final String reason;

  bool get acknowledged =>
      state == RecommendationCanaryManifestAcknowledgementState.acknowledged;

  bool get authorizesCanaryActivation => false;
  bool get authorizesCanaryExpansion => false;
  bool get authorizesCanaryDeactivation => false;
  bool get authorizesFullRollout => false;
}

class V2RecommendationCanaryManifestService {
  V2RecommendationCanaryManifestService({
    required this.expectedAudience,
    required this.expectedEnvironment,
    Map<String, List<int>> trustedPublicKeys = const {},
    FlutterSecureStorage? secureStorage,
    V2CanaryManifestStateReader? stateReader,
    V2CanaryManifestStateWriter? stateWriter,
    V2CanaryManifestSignatureVerifier? signatureVerifier,
    DateTime Function()? clock,
    this.maximumManifestBytes = 16 * 1024,
    this.maximumFutureClockSkew = const Duration(minutes: 5),
  })  : assert(maximumManifestBytes > 0),
        assert(!maximumFutureClockSkew.isNegative),
        assert((stateReader == null) == (stateWriter == null)),
        trustedPublicKeys = Map.unmodifiable({
          for (final entry in trustedPublicKeys.entries)
            entry.key: List<int>.unmodifiable(entry.value),
        }),
        _stateReader = stateReader ?? _buildStateReader(secureStorage),
        _stateWriter = stateWriter ?? _buildStateWriter(secureStorage),
        _signatureVerifier = signatureVerifier ?? _verifyEd25519,
        _clock = clock ?? DateTime.now;

  static const String stagedStateSchemaVersion = 'v1';
  static const String _stagedStateKey =
      'v2_recommendation_canary_staged_manifest_v1';

  final String expectedAudience;
  final String expectedEnvironment;
  final Map<String, List<int>> trustedPublicKeys;
  final V2CanaryManifestStateReader _stateReader;
  final V2CanaryManifestStateWriter _stateWriter;
  final V2CanaryManifestSignatureVerifier _signatureVerifier;
  final DateTime Function() _clock;
  final int maximumManifestBytes;
  final Duration maximumFutureClockSkew;
  Future<void> _pendingOperation = Future<void>.value();

  Future<RecommendationCanaryManifestIngestionResult> ingest(
    String rawManifest,
  ) {
    return _enqueue(() async {
      if (!_hasUsableTrustStore) {
        return _result(
          RecommendationCanaryManifestIngestionState.trustStoreUnconfigured,
          'canary_manifest_trust_store_unconfigured',
        );
      }
      if (rawManifest.length > maximumManifestBytes ||
          utf8.encode(rawManifest).length > maximumManifestBytes) {
        return _result(
          RecommendationCanaryManifestIngestionState.manifestTooLarge,
          'canary_manifest_too_large',
        );
      }

      final signedManifest = _decodeSignedManifest(rawManifest);
      if (signedManifest == null) {
        return _result(
          RecommendationCanaryManifestIngestionState.malformed,
          'canary_manifest_malformed',
        );
      }
      final manifest = signedManifest.manifest;
      final publicKey = trustedPublicKeys[signedManifest.keyId];
      if (publicKey == null || publicKey.length != 32) {
        return _result(
          RecommendationCanaryManifestIngestionState.unknownKey,
          'canary_manifest_unknown_key',
        );
      }
      final canonicalPayload = manifest.canonicalPayloadBytes();
      final validSignature = await _verifySignature(
        message: canonicalPayload,
        signature: signedManifest.signatureBytes,
        publicKey: publicKey,
      );
      if (!validSignature) {
        return _result(
          RecommendationCanaryManifestIngestionState.invalidSignature,
          'canary_manifest_signature_invalid',
        );
      }
      if (manifest.audience != expectedAudience) {
        return _result(
          RecommendationCanaryManifestIngestionState.wrongAudience,
          'canary_manifest_audience_mismatch',
          manifest: manifest,
        );
      }
      if (manifest.environment != expectedEnvironment) {
        return _result(
          RecommendationCanaryManifestIngestionState.wrongEnvironment,
          'canary_manifest_environment_mismatch',
          manifest: manifest,
        );
      }

      final now = _clock().toUtc();
      if (manifest.issuedAt.isAfter(now.add(maximumFutureClockSkew))) {
        return _result(
          RecommendationCanaryManifestIngestionState.issuedInFuture,
          'canary_manifest_issued_in_future',
          manifest: manifest,
        );
      }
      if (!manifest.expiresAt.isAfter(now)) {
        return _result(
          RecommendationCanaryManifestIngestionState.expired,
          'canary_manifest_expired',
          manifest: manifest,
        );
      }

      try {
        final existingRaw = await _stateReader();
        final existing = _decodeStagedState(existingRaw);
        if (existingRaw != null && existing == null) {
          return _result(
            RecommendationCanaryManifestIngestionState.stagedStateInvalid,
            'canary_manifest_staged_state_invalid',
            manifest: manifest,
          );
        }
        if (existing != null &&
            !await _isTrustedStagedState(existing, now: now)) {
          return _result(
            RecommendationCanaryManifestIngestionState.stagedStateInvalid,
            'canary_manifest_staged_state_untrusted',
            manifest: manifest,
          );
        }
        if (existing != null && manifest.revision <= existing.highestRevision) {
          return _result(
            RecommendationCanaryManifestIngestionState.replayedOrStale,
            'canary_manifest_revision_not_monotonic',
            manifest: manifest,
          );
        }

        final digest = sha256.convert(canonicalPayload).toString();
        final acceptedAt = now;
        final stagedState = _RecommendationCanaryStagedState(
          highestRevision: manifest.revision,
          acceptedAt: acceptedAt,
          reviewedAt: null,
          payloadDigest: digest,
          signedManifest: signedManifest,
        );
        final saved = await _stateWriter(jsonEncode(stagedState.toJson()));
        if (!saved) {
          return _result(
            RecommendationCanaryManifestIngestionState.storageUnavailable,
            'canary_manifest_staging_failed',
            manifest: manifest,
          );
        }
        return RecommendationCanaryManifestIngestionResult(
          state: RecommendationCanaryManifestIngestionState
              .acceptedForManualReview,
          reason: manifest.proposesControlledCanary
              ? 'canary_manifest_staged_for_manual_canary_review'
              : 'canary_manifest_disable_staged_for_manual_review',
          manifest: manifest,
          payloadDigest: digest,
        );
      } catch (_) {
        return _result(
          RecommendationCanaryManifestIngestionState.storageUnavailable,
          'canary_manifest_storage_unavailable',
          manifest: manifest,
        );
      }
    });
  }

  Future<RecommendationCanaryStagedManifestInspection>
      inspectStagedManifest() async {
    try {
      final raw = await _stateReader();
      if (raw == null) {
        return const RecommendationCanaryStagedManifestInspection(
          state: RecommendationCanaryStagedManifestState.absent,
        );
      }
      final state = _decodeStagedState(raw);
      final now = _clock().toUtc();
      if (state == null || !await _isTrustedStagedState(state, now: now)) {
        return const RecommendationCanaryStagedManifestInspection(
          state: RecommendationCanaryStagedManifestState.invalid,
        );
      }
      final manifest = state.signedManifest.manifest;
      if (state.reviewedAt != null) {
        return RecommendationCanaryStagedManifestInspection(
          state: RecommendationCanaryStagedManifestState.reviewed,
          manifest: manifest,
          acceptedAt: state.acceptedAt,
          payloadDigest: state.payloadDigest,
        );
      }
      if (!manifest.expiresAt.isAfter(now)) {
        return RecommendationCanaryStagedManifestInspection(
          state: RecommendationCanaryStagedManifestState.expired,
          manifest: manifest,
          acceptedAt: state.acceptedAt,
          payloadDigest: state.payloadDigest,
        );
      }
      return RecommendationCanaryStagedManifestInspection(
        state: RecommendationCanaryStagedManifestState.staged,
        manifest: manifest,
        acceptedAt: state.acceptedAt,
        payloadDigest: state.payloadDigest,
      );
    } catch (_) {
      return const RecommendationCanaryStagedManifestInspection(
        state: RecommendationCanaryStagedManifestState.unavailable,
      );
    }
  }

  Future<RecommendationCanaryManifestAcknowledgementResult>
      acknowledgeManualReview({
    required int revision,
    required String payloadDigest,
  }) {
    return _enqueue(() async {
      if (revision <= 0 || !_safeDigest.hasMatch(payloadDigest)) {
        return _acknowledgement(
          RecommendationCanaryManifestAcknowledgementState.tokenMismatch,
          'canary_manifest_acknowledgement_token_invalid',
        );
      }
      try {
        final raw = await _stateReader();
        if (raw == null) {
          return _acknowledgement(
            RecommendationCanaryManifestAcknowledgementState.noStagedManifest,
            'canary_manifest_not_staged',
          );
        }
        final state = _decodeStagedState(raw);
        final now = _clock().toUtc();
        if (state == null || !await _isTrustedStagedState(state, now: now)) {
          return _acknowledgement(
            RecommendationCanaryManifestAcknowledgementState.stagedStateInvalid,
            'canary_manifest_staged_state_invalid',
          );
        }
        if (revision != state.highestRevision ||
            payloadDigest != state.payloadDigest) {
          return _acknowledgement(
            RecommendationCanaryManifestAcknowledgementState.tokenMismatch,
            'canary_manifest_acknowledgement_token_mismatch',
          );
        }
        if (state.reviewedAt != null) {
          return _acknowledgement(
            RecommendationCanaryManifestAcknowledgementState
                .alreadyAcknowledged,
            'canary_manifest_already_acknowledged',
          );
        }
        if (!state.signedManifest.manifest.expiresAt.isAfter(now)) {
          return _acknowledgement(
            RecommendationCanaryManifestAcknowledgementState.expired,
            'canary_manifest_acknowledgement_expired',
          );
        }
        final reviewed = state.copyWith(reviewedAt: now);
        final saved = await _stateWriter(jsonEncode(reviewed.toJson()));
        if (!saved) {
          return _acknowledgement(
            RecommendationCanaryManifestAcknowledgementState.storageUnavailable,
            'canary_manifest_acknowledgement_write_failed',
          );
        }
        return _acknowledgement(
          RecommendationCanaryManifestAcknowledgementState.acknowledged,
          'canary_manifest_manual_review_acknowledged',
        );
      } catch (_) {
        return _acknowledgement(
          RecommendationCanaryManifestAcknowledgementState.storageUnavailable,
          'canary_manifest_acknowledgement_storage_unavailable',
        );
      }
    });
  }

  Future<T> _enqueue<T>(Future<T> Function() operation) {
    final result = _pendingOperation.then((_) => operation());
    _pendingOperation = result.then<void>(
      (_) {},
      onError: (_, __) {},
    );
    return result;
  }

  Future<bool> _verifySignature({
    required List<int> message,
    required List<int> signature,
    required List<int> publicKey,
  }) async {
    try {
      return await _signatureVerifier(
        message: message,
        signature: signature,
        publicKey: publicKey,
      );
    } catch (_) {
      return false;
    }
  }

  Future<bool> _isTrustedStagedState(
    _RecommendationCanaryStagedState state, {
    DateTime? now,
  }) async {
    final signedManifest = state.signedManifest;
    final manifest = signedManifest.manifest;
    final publicKey = trustedPublicKeys[signedManifest.keyId];
    final inspectedAt = (now ?? _clock()).toUtc();
    if (publicKey == null ||
        publicKey.length != 32 ||
        manifest.audience != expectedAudience ||
        manifest.environment != expectedEnvironment ||
        state.acceptedAt.isAfter(inspectedAt.add(maximumFutureClockSkew)) ||
        (state.reviewedAt != null &&
            (state.reviewedAt!.isBefore(state.acceptedAt) ||
                state.reviewedAt!.isAfter(
                  inspectedAt.add(maximumFutureClockSkew),
                ))) ||
        state.acceptedAt.isBefore(
          manifest.issuedAt.subtract(maximumFutureClockSkew),
        ) ||
        !manifest.expiresAt.isAfter(state.acceptedAt)) {
      return false;
    }
    return _verifySignature(
      message: manifest.canonicalPayloadBytes(),
      signature: signedManifest.signatureBytes,
      publicKey: publicKey,
    );
  }

  RecommendationCanarySignedManifest? _decodeSignedManifest(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      return RecommendationCanarySignedManifest.tryFromJson(
        Map<String, dynamic>.from(decoded),
      );
    } catch (_) {
      return null;
    }
  }

  _RecommendationCanaryStagedState? _decodeStagedState(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      return _RecommendationCanaryStagedState.tryFromJson(
        Map<String, dynamic>.from(decoded),
      );
    } catch (_) {
      return null;
    }
  }

  RecommendationCanaryManifestIngestionResult _result(
    RecommendationCanaryManifestIngestionState state,
    String reason, {
    RecommendationCanaryManifest? manifest,
  }) {
    return RecommendationCanaryManifestIngestionResult(
      state: state,
      reason: reason,
      manifest: manifest,
    );
  }

  RecommendationCanaryManifestAcknowledgementResult _acknowledgement(
    RecommendationCanaryManifestAcknowledgementState state,
    String reason,
  ) {
    return RecommendationCanaryManifestAcknowledgementResult(
      state: state,
      reason: reason,
    );
  }

  static Future<bool> _verifyEd25519({
    required List<int> message,
    required List<int> signature,
    required List<int> publicKey,
  }) {
    return Ed25519().verify(
      message,
      signature: Signature(
        signature,
        publicKey: SimplePublicKey(
          publicKey,
          type: KeyPairType.ed25519,
        ),
      ),
    );
  }

  static V2CanaryManifestStateReader _buildStateReader(
    FlutterSecureStorage? storage,
  ) {
    final resolved = storage ?? const FlutterSecureStorage();
    return () => resolved.read(key: _stagedStateKey);
  }

  static V2CanaryManifestStateWriter _buildStateWriter(
    FlutterSecureStorage? storage,
  ) {
    final resolved = storage ?? const FlutterSecureStorage();
    return (value) async {
      await resolved.write(key: _stagedStateKey, value: value);
      return await resolved.read(key: _stagedStateKey) == value;
    };
  }

  bool get _hasUsableTrustStore {
    return trustedPublicKeys.entries.any(
      (entry) => _safeKeyId.hasMatch(entry.key) && entry.value.length == 32,
    );
  }

  static final RegExp _safeKeyId = RegExp(r'^[a-zA-Z0-9_.-]{1,64}$');
  static final RegExp _safeDigest = RegExp(r'^[a-f0-9]{64}$');
}

class _RecommendationCanaryStagedState {
  const _RecommendationCanaryStagedState({
    required this.highestRevision,
    required this.acceptedAt,
    required this.reviewedAt,
    required this.payloadDigest,
    required this.signedManifest,
  });

  final int highestRevision;
  final DateTime acceptedAt;
  final DateTime? reviewedAt;
  final String payloadDigest;
  final RecommendationCanarySignedManifest signedManifest;

  Map<String, Object?> toJson() {
    return {
      'schema_version':
          V2RecommendationCanaryManifestService.stagedStateSchemaVersion,
      'highest_revision': highestRevision,
      'accepted_at': acceptedAt.toUtc().toIso8601String(),
      'reviewed_at': reviewedAt?.toUtc().toIso8601String(),
      'payload_digest': payloadDigest,
      'signed_manifest': signedManifest.toJson(),
    };
  }

  _RecommendationCanaryStagedState copyWith({DateTime? reviewedAt}) {
    return _RecommendationCanaryStagedState(
      highestRevision: highestRevision,
      acceptedAt: acceptedAt,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      payloadDigest: payloadDigest,
      signedManifest: signedManifest,
    );
  }

  static _RecommendationCanaryStagedState? tryFromJson(
    Map<String, dynamic> json,
  ) {
    const keys = {
      'schema_version',
      'highest_revision',
      'accepted_at',
      'reviewed_at',
      'payload_digest',
      'signed_manifest',
    };
    if (json.length != keys.length || !json.keys.toSet().containsAll(keys)) {
      return null;
    }
    final highestRevision = json['highest_revision'];
    final acceptedAtRaw = json['accepted_at'];
    final reviewedAtRaw = json['reviewed_at'];
    final payloadDigest = json['payload_digest'];
    final signedManifestRaw = json['signed_manifest'];
    if (json['schema_version'] !=
            V2RecommendationCanaryManifestService.stagedStateSchemaVersion ||
        highestRevision is! int ||
        highestRevision <= 0 ||
        acceptedAtRaw is! String ||
        !acceptedAtRaw.endsWith('Z') ||
        (reviewedAtRaw != null &&
            (reviewedAtRaw is! String || !reviewedAtRaw.endsWith('Z'))) ||
        payloadDigest is! String ||
        !_safeDigest.hasMatch(payloadDigest) ||
        signedManifestRaw is! Map) {
      return null;
    }
    final acceptedAt = DateTime.tryParse(acceptedAtRaw)?.toUtc();
    final reviewedAt = reviewedAtRaw == null
        ? null
        : DateTime.tryParse(reviewedAtRaw as String)?.toUtc();
    final signedManifest = RecommendationCanarySignedManifest.tryFromJson(
      Map<String, dynamic>.from(signedManifestRaw),
    );
    if (acceptedAt == null ||
        (reviewedAtRaw != null && reviewedAt == null) ||
        signedManifest == null ||
        signedManifest.manifest.revision != highestRevision ||
        sha256
                .convert(signedManifest.manifest.canonicalPayloadBytes())
                .toString() !=
            payloadDigest) {
      return null;
    }
    return _RecommendationCanaryStagedState(
      highestRevision: highestRevision,
      acceptedAt: acceptedAt,
      reviewedAt: reviewedAt,
      payloadDigest: payloadDigest,
      signedManifest: signedManifest,
    );
  }

  static final RegExp _safeDigest = RegExp(r'^[a-f0-9]{64}$');
}
