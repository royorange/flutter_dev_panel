/// DevPanel API 访问器
/// 
/// 这个类用于提供模块 API 的访问点，支持扩展
/// 通过 DevPanel.get() 获取实例
class DevPanelAPI {
  const DevPanelAPI._();
  
  /// 单例实例
  static const DevPanelAPI _instance = DevPanelAPI._();
  
  /// 获取实例
  static DevPanelAPI get instance => _instance;
}