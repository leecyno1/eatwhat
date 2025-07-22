// 浏览器控制台调试脚本
// 在Chrome DevTools控制台中运行此脚本来监控气泡状态

function startBubbleMonitoring() {
    console.log('🔬 开始监控气泡状态...');
    
    // 监控DOM变化
    const observer = new MutationObserver((mutations) => {
        mutations.forEach((mutation) => {
            if (mutation.type === 'childList') {
                const bubbles = document.querySelectorAll('[data-entity-id]');
                console.log(`气泡数量: ${bubbles.length}`);
                
                bubbles.forEach((bubble, index) => {
                    const style = bubble.style;
                    const transform = style.transform;
                    const left = style.left;
                    const top = style.top;
                    
                    if (index < 3) { // 只显示前3个气泡的状态
                        console.log(`气泡${index}: left=${left}, top=${top}, transform=${transform}`);
                    }
                });
            }
            
            if (mutation.type === 'attributes' && mutation.attributeName === 'style') {
                const element = mutation.target;
                if (element.hasAttribute('data-entity-id')) {
                    console.log('🔄 气泡样式变化:', {
                        id: element.getAttribute('data-entity-id'),
                        left: element.style.left,
                        top: element.style.top,
                        transform: element.style.transform
                    });
                }
            }
        });
    });
    
    // 开始观察
    observer.observe(document.body, {
        childList: true,
        subtree: true,
        attributes: true,
        attributeFilter: ['style']
    });
    
    // 性能监控
    let frameCount = 0;
    let lastTime = performance.now();
    
    function checkPerformance() {
        frameCount++;
        const currentTime = performance.now();
        
        if (currentTime - lastTime >= 1000) {
            const fps = frameCount / ((currentTime - lastTime) / 1000);
            console.log(`📊 FPS: ${fps.toFixed(1)}`);
            frameCount = 0;
            lastTime = currentTime;
        }
        
        requestAnimationFrame(checkPerformance);
    }
    
    checkPerformance();
    
    return observer;
}

// 检查当前气泡状态
function checkBubbleStatus() {
    const bubbles = document.querySelectorAll('[class*="physical"], [class*="bubble"], [class*="entity"]');
    console.log('🎯 找到的气泡元素:', bubbles.length);
    
    bubbles.forEach((bubble, index) => {
        const rect = bubble.getBoundingClientRect();
        const style = getComputedStyle(bubble);
        
        console.log(`气泡 ${index}:`, {
            className: bubble.className,
            position: {
                x: rect.left,
                y: rect.top,
                width: rect.width,
                height: rect.height
            },
            transform: style.transform,
            animation: style.animation,
            transition: style.transition
        });
    });
}

// 立即检查状态
checkBubbleStatus();

// 启动监控（可选）
// const monitor = startBubbleMonitoring();

console.log('🚀 调试脚本已加载！');
console.log('💡 运行 checkBubbleStatus() 来检查当前状态');
console.log('💡 运行 startBubbleMonitoring() 来开始实时监控');