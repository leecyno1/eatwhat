#!/bin/bash

# 真机测试快速启动脚本
# 用于《吃什么》应用的真机构建、安装和测试

set -e  # 遇到错误立即退出

echo "🚀 开始《吃什么》应用真机测试流程..."

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 项目配置
PROJECT_ROOT="/Users/lichengyin/Desktop/Projects/eatwhat"
WORKSPACE_PATH="$PROJECT_ROOT/ios/Runner.xcworkspace"
SCHEME="Runner"
BUNDLE_ID="com.eatwhat.eatwhatApp"

# 函数: 打印状态信息
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 函数: 检查依赖
check_dependencies() {
    print_status "检查开发环境依赖..."
    
    # 检查Flutter
    if ! command -v flutter &> /dev/null; then
        print_error "Flutter未安装或不在PATH中"
        exit 1
    fi
    
    # 检查Xcode
    if ! command -v xcodebuild &> /dev/null; then
        print_error "Xcode命令行工具未安装"
        exit 1
    fi
    
    print_success "开发环境检查通过"
}

# 函数: 列出可用设备
list_devices() {
    print_status "扫描可用设备..."
    
    echo "📱 Flutter设备列表:"
    flutter devices
    
    echo ""
    echo "📱 已连接的iOS设备:"
    # 使用MCP工具列出设备（如果可用）
    # 这里需要实际的MCP命令来列出设备
}

# 函数: 清理构建缓存
clean_build() {
    print_status "清理构建缓存..."
    
    cd "$PROJECT_ROOT"
    flutter clean
    rm -rf ios/build/
    
    print_success "构建缓存清理完成"
}

# 函数: 获取依赖
get_dependencies() {
    print_status "获取Flutter依赖..."
    
    cd "$PROJECT_ROOT"
    flutter pub get
    
    print_success "依赖获取完成"
}

# 函数: 构建应用
build_app() {
    local device_id=$1
    
    if [ -z "$device_id" ]; then
        print_error "未指定设备ID"
        exit 1
    fi
    
    print_status "为设备 $device_id 构建应用..."
    
    cd "$PROJECT_ROOT"
    
    # 使用Flutter构建（推荐方式）
    flutter build ios --debug --device-id="$device_id"
    
    print_success "应用构建完成"
}

# 函数: 安装并运行应用
install_and_run() {
    local device_id=$1
    
    if [ -z "$device_id" ]; then
        print_error "未指定设备ID"
        exit 1
    fi
    
    print_status "在设备 $device_id 上安装并运行应用..."
    
    cd "$PROJECT_ROOT"
    
    # 使用Flutter直接运行（最简单的方式）
    flutter run -d "$device_id" --debug
}

# 函数: 快速测试
quick_test() {
    local device_id=$1
    
    print_status "执行快速测试流程..."
    
    # 检查依赖
    check_dependencies
    
    # 获取依赖
    get_dependencies
    
    # 构建并运行
    install_and_run "$device_id"
}

# 函数: 完整测试
full_test() {
    local device_id=$1
    
    print_status "执行完整测试流程..."
    
    # 检查依赖
    check_dependencies
    
    # 清理缓存
    clean_build
    
    # 获取依赖
    get_dependencies
    
    # 构建应用
    build_app "$device_id"
    
    # 安装并运行
    install_and_run "$device_id"
}

# 函数: 显示帮助信息
show_help() {
    echo "《吃什么》应用真机测试脚本"
    echo ""
    echo "用法:"
    echo "  $0 [选项] [设备ID]"
    echo ""
    echo "选项:"
    echo "  -h, --help          显示此帮助信息"
    echo "  -l, --list          列出可用设备"
    echo "  -q, --quick         快速测试（不清理缓存）"
    echo "  -f, --full          完整测试（清理缓存）"
    echo "  -c, --clean         仅清理构建缓存"
    echo "  -d, --deps          仅获取依赖"
    echo ""
    echo "示例:"
    echo "  $0 --list                           # 列出设备"
    echo "  $0 --quick 00008140-001C29D93E60801C  # 快速测试"
    echo "  $0 --full 00008140-001C29D93E60801C   # 完整测试"
    echo ""
    echo "常用设备ID:"
    echo "  iPhone 12pm (wireless): 00008140-001C29D93E60801C"
    echo "  iPhone 16 (simulator):  4BB85071-ABFF-4D40-8FF0-6FE008A7CB12"
}

# 主程序
main() {
    case "$1" in
        -h|--help)
            show_help
            ;;
        -l|--list)
            list_devices
            ;;
        -q|--quick)
            if [ -z "$2" ]; then
                print_error "请指定设备ID"
                show_help
                exit 1
            fi
            quick_test "$2"
            ;;
        -f|--full)
            if [ -z "$2" ]; then
                print_error "请指定设备ID"
                show_help
                exit 1
            fi
            full_test "$2"
            ;;
        -c|--clean)
            clean_build
            ;;
        -d|--deps)
            get_dependencies
            ;;
        "")
            show_help
            ;;
        *)
            # 如果第一个参数看起来像设备ID，则进行快速测试
            if [[ "$1" =~ ^[0-9A-F]{8}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{12}$ ]]; then
                quick_test "$1"
            else
                print_error "未知选项: $1"
                show_help
                exit 1
            fi
            ;;
    esac
}

# 捕获Ctrl+C信号
trap 'print_warning "\n测试已取消"; exit 1' INT

# 执行主程序
main "$@"
