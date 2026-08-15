# Code Quality Standards

## Dart Analysis Rules

### Enabled Lints
- `prefer_const_constructors` - Use const constructors where possible
- `prefer_const_literals_to_create_immutables` - Use const for immutable collections
- `avoid_print` - Use debugPrint instead of print
- `prefer_single_quotes` - Use single quotes for strings
- `unnecessary_null_checks` - Remove unnecessary null checks
- `prefer_final_fields` - Use final for fields that don't change
- `avoid_unnecessary_containers` - Remove unnecessary Container widgets
- `sized_box_for_whitespace` - Use SizedBox instead of Container for spacing
- `use_key_in_widget_constructors` - Add key parameter to widgets
- `prefer_typing_uninitialized_variables` - Type uninitialized variables
- `avoid_init_to_null` - Don't initialize to null explicitly
- `prefer_is_empty` - Use isEmpty instead of length == 0
- `prefer_is_not_empty` - Use isNotEmpty instead of length > 0
- `avoid_returning_null_for_void` - Don't return null for void functions
- `prefer_void_to_null` - Use void instead of Null
- `avoid_slow_async_io` - Avoid slow async I/O operations
- `cancel_subscriptions` - Cancel stream subscriptions
- `close_sinks` - Close StreamController sinks
- `avoid_web_libraries_in_flutter` - Don't import dart:html in Flutter

### Performance Rules
- `avoid_function_literals_in_foreach_calls` - Use for loops instead
- `prefer_foreach` - Use forEach for simple iterations
- `prefer_for_elements_to_map_fromIterable` - Use for elements in collections
- `prefer_if_elements_to_conditional_expressions` - Use if elements in collections

### Code Style
- `always_declare_return_types` - Declare return types
- `always_put_required_named_parameters_first` - Required params first
- `annotate_overrides` - Annotate @override
- `avoid_bool_literals_in_conditional_expressions` - Simplify bool expressions
- `avoid_catches_without_on_clauses` - Specify exception types
- `avoid_catching_errors` - Catch Exception, not Error
- `avoid_double_and_int_checks` - Use num for numeric checks
- `avoid_empty_else` - Remove empty else blocks
- `avoid_field_initializers_in_const_classes` - Use const constructors
- `avoid_implementing_value_types` - Don't implement value types
- `avoid_js_rounded_ints` - Be careful with large integers
- `avoid_null_checks_in_equality_operators` - Handle null in == operator
- `avoid_positional_boolean_parameters` - Use named bool parameters
- `avoid_private_typedef_functions` - Make typedefs public
- `avoid_redundant_argument_values` - Remove redundant arguments
- `avoid_relative_lib_imports` - Use package: imports
- `avoid_renaming_method_parameters` - Keep parameter names consistent
- `avoid_return_types_on_setters` - Setters don't have return types
- `avoid_returning_null` - Return non-null values
- `avoid_returning_null_for_future` - Return Future, not null
- `avoid_returning_this` - Avoid returning this for chaining
- `avoid_setters_without_getters` - Add getters for setters
- `avoid_shadowing_type_parameters` - Don't shadow type parameters
- `avoid_single_cascade_in_expression_statements` - Use multiple cascades
- `avoid_types_as_parameter_names` - Don't use types as parameter names
- `avoid_types_on_closure_parameters` - Infer closure parameter types
- `avoid_unused_constructor_parameters` - Remove unused parameters
- `avoid_void_async` - Use Future<void> instead of void async
- `await_only_futures` - Only await Futures
- `camel_case_extensions` - Use camelCase for extensions
- `camel_case_types` - Use CamelCase for types
- `cascade_invocations` - Use cascade notation
- `constant_identifier_names` - Use SCREAMING_CAPS for constants
- `curly_braces_in_flow_control_structures` - Always use braces
- `directives_ordering` - Order imports correctly
- `empty_catches` - Don't use empty catch blocks
- `empty_constructor_bodies` - Use ; for empty constructors
- `empty_statements` - Remove empty statements
- `exhaustive_cases` - Handle all enum cases
- `file_names` - Use snake_case for file names
- `hash_and_equals` - Override both hashCode and ==
- `implementation_imports` - Don't import implementation files
- `iterable_contains_unrelated_type` - Check contains with correct type
- `join_return_with_assignment` - Combine return with assignment
- `leading_newlines_in_multiline_strings` - Start multiline strings with newline
- `library_names` - Use lowercase_with_underscores for library names
- `library_prefixes` - Use lowercase_with_underscores for prefixes
- `list_remove_unrelated_type` - Remove with correct type
- `literal_only_boolean_expressions` - Simplify boolean expressions
- `missing_whitespace_between_adjacent_strings` - Add whitespace between strings
- `no_adjacent_strings_in_list` - Don't use adjacent strings in lists
- `no_duplicate_case_values` - Remove duplicate case values
- `no_logic_in_create_state` - Keep createState simple
- `non_constant_identifier_names` - Use camelCase for identifiers
- `null_check_on_nullable_type_parameter` - Check null on nullable types
- `null_closures` - Use null instead of () => null
- `omit_local_variable_types` - Omit obvious types
- `one_member_abstracts` - Use functions instead of single-method abstracts
- `only_throw_errors` - Only throw Error or Exception
- `overridden_fields` - Don't override fields
- `package_api_docs` - Document public APIs
- `package_names` - Use lowercase_with_underscores for packages
- `package_prefixed_library_names` - Prefix library names with package
- `parameter_assignments` - Don't reassign parameters
- `prefer_adjacent_string_concatenation` - Use adjacent strings
- `prefer_asserts_in_initializer_lists` - Put asserts in initializer lists
- `prefer_asserts_with_message` - Add messages to asserts
- `prefer_collection_literals` - Use collection literals
- `prefer_conditional_assignment` - Use ??= for conditional assignment
- `prefer_const_constructors_in_immutables` - Use const in immutable classes
- `prefer_const_declarations` - Use const for declarations
- `prefer_constructors_over_static_methods` - Use constructors
- `prefer_contains` - Use contains instead of indexOf
- `prefer_equal_for_default_values` - Use = for default values
- `prefer_expression_function_bodies` - Use => for simple functions
- `prefer_final_in_for_each` - Use final in forEach
- `prefer_final_locals` - Use final for local variables
- `prefer_function_declarations_over_variables` - Declare functions directly
- `prefer_generic_function_type_aliases` - Use generic function types
- `prefer_if_null_operators` - Use ?? operator
- `prefer_initializing_formals` - Use this.field in constructors
- `prefer_inlined_adds` - Inline collection adds
- `prefer_int_literals` - Use int literals
- `prefer_interpolation_to_compose_strings` - Use string interpolation
- `prefer_is_not_operator` - Use is! operator
- `prefer_iterable_whereType` - Use whereType for filtering
- `prefer_mixin` - Use mixin instead of abstract class
- `prefer_null_aware_operators` - Use ?. operator
- `prefer_relative_imports` - Use relative imports within package
- `prefer_spread_collections` - Use spread operator
- `provide_deprecation_message` - Add deprecation messages
- `recursive_getters` - Avoid recursive getters
- `slash_for_doc_comments` - Use /// for doc comments
- `sort_child_properties_last` - Put child property last
- `sort_constructors_first` - Put constructors first
- `sort_unnamed_constructors_first` - Put unnamed constructor first
- `test_types_in_equals` - Check types in == operator
- `throw_in_finally` - Don't throw in finally
- `type_annotate_public_apis` - Annotate public API types
- `type_init_formals` - Don't type initializing formals
- `unawaited_futures` - Await or ignore futures
- `unnecessary_await_in_return` - Remove unnecessary await
- `unnecessary_brace_in_string_interps` - Remove unnecessary braces
- `unnecessary_const` - Remove unnecessary const
- `unnecessary_getters_setters` - Remove trivial getters/setters
- `unnecessary_lambdas` - Remove unnecessary lambdas
- `unnecessary_new` - Remove unnecessary new
- `unnecessary_null_aware_assignments` - Remove unnecessary ??=
- `unnecessary_null_in_if_null_operators` - Remove unnecessary null
- `unnecessary_overrides` - Remove unnecessary overrides
- `unnecessary_parenthesis` - Remove unnecessary parenthesis
- `unnecessary_raw_strings` - Remove unnecessary raw strings
- `unnecessary_statements` - Remove unnecessary statements
- `unnecessary_string_escapes` - Remove unnecessary escapes
- `unnecessary_string_interpolations` - Remove unnecessary interpolations
- `unnecessary_this` - Remove unnecessary this
- `unrelated_type_equality_checks` - Check equality with correct types
- `unsafe_html` - Avoid unsafe HTML
- `use_full_hex_values_for_flutter_colors` - Use full hex for colors
- `use_function_type_syntax_for_parameters` - Use function type syntax
- `use_rethrow_when_possible` - Use rethrow instead of throw
- `use_setters_to_change_properties` - Use setters for property changes
- `use_string_buffers` - Use StringBuffer for concatenation
- `use_to_and_as_if_applicable` - Use to/as for conversions
- `valid_regexps` - Use valid regular expressions
- `void_checks` - Check void return types

## Testing Standards

### Test Coverage Requirements
- Minimum 80% code coverage for core services
- 100% coverage for critical business logic
- All public APIs must have tests

### Test Organization
- Group related tests with `group()`
- Use descriptive test names in Chinese
- Follow AAA pattern: Arrange, Act, Assert
- Use `setUp()` and `tearDown()` for test fixtures

### Mock Guidelines
- Create mocks in `test/helpers/` directory
- Use `implements` for interface mocking
- Provide fake implementations for complex dependencies
- Document mock behavior in comments

## Documentation Standards

### Code Comments
- Use `///` for public API documentation
- Use `//` for implementation comments
- Document complex algorithms and business logic
- Include examples for non-obvious usage

### README Requirements
- Project overview and features
- Setup instructions
- Architecture documentation
- Contributing guidelines

## Git Commit Standards

### Commit Message Format
```
<type>: <subject>

<body>

<footer>
```

### Types
- `feat`: New feature
- `fix`: Bug fix
- `refactor`: Code refactoring
- `perf`: Performance improvement
- `test`: Adding tests
- `docs`: Documentation
- `style`: Code style changes
- `chore`: Build/tooling changes

### Examples
```
feat: 添加基于余弦相似度的推荐算法优化

实现了46维口味向量的余弦相似度计算，提升推荐准确度15%。

Closes #123
```

## Performance Standards

### Widget Performance
- Use `const` constructors wherever possible
- Implement `shouldRebuild` for custom widgets
- Avoid expensive operations in `build()` methods
- Use `ListView.builder` for long lists
- Cache expensive computations

### Memory Management
- Dispose controllers and streams
- Use object pools for frequently created objects
- Implement proper cleanup in `dispose()`
- Monitor memory usage with PerformanceMonitor

### Network Performance
- Implement request caching
- Use pagination for large datasets
- Compress images before upload
- Implement retry logic with exponential backoff

## Security Standards

### Data Protection
- Never commit API keys or secrets
- Use SecureStorage for sensitive data
- Sanitize user input
- Implement proper authentication

### Code Security
- Validate all external input
- Use parameterized queries
- Implement rate limiting
- Follow OWASP guidelines
