# 🚀 手动测试命令

## 在终端中执行以下命令：

### 1. 切换到项目目录
```bash
cd /Users/lichengyin/Desktop/Projects/eatwhat
```

### 2. 检查设备连接
```bash
flutter devices
```

### 3. 运行应用到iOS设备
```bash
# 如果有iPhone连接
flutter run -d ios --release

# 或者指定具体设备ID（从第2步获取）
flutter run -d [设备ID] --release
```

### 4. 或者在Xcode中运行
```bash
# 打开iOS项目
open ios/Runner.xcworkspace
```

## 🎯 测试重点

1. **30项随机显示**：每次启动观察气泡组合
2. **动态大小变化**：多次向上滑动同一气泡
3. **滑动替换**：向下滑动观察新气泡出现
4. **数据持久化**：重启app验证偏好保存

## 📱 如果设备未连接

如果没有iPhone设备，可以使用iOS模拟器：

```bash
# 启动iOS模拟器
open -a Simulator

# 运行到模拟器
flutter run -d ios --debug
```

## ✅ 预期看到的效果

- 30个随机气泡显示
- 向上滑动气泡会逐渐变大
- 向下滑动会替换为新气泡
- 控制台输出用户偏好日志
- 粒子效果反馈

立即运行这些命令来测试新的用户偏好系统！