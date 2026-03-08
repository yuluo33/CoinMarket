import Foundation
import Combine

final class LocalizationManager: ObservableObject {
    static let shared = LocalizationManager()
    
    private let settings = SettingsManager.shared
    
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        // 监听语言变化，触发objectWillChange
        settings.$language
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }
    
    private var translations: [AppLanguage: [String: String]] = [
        .zh: [
            "设置": "设置",
            "语言": "语言",
            "价格单位": "价格单位",
            "搜索币种": "搜索币种",
            "自动刷新间隔": "自动刷新间隔",
            "状态栏轮播间隔": "状态栏轮播间隔",
            "API 数据源": "API 数据源",
            "Powered by Binance": "Powered by Binance",
            "CoinMarket": "CoinMarket",
            "更新:": "更新:",
            "加载中...": "加载中...",
            "加载失败": "加载失败",
            "重试": "重试",
            "未找到相关币种": "未找到相关币种",
            "请尝试其他搜索词": "请尝试其他搜索词",
            "搜索币种...": "搜索币种...",
            "我的收藏": "我的收藏",
            "暂无收藏": "暂无收藏",
            "点击货币旁的星标添加收藏": "点击货币旁的星标添加收藏",
            "打开主窗口": "打开主窗口",
            "价格单位:": "价格单位:",
            "已收藏": "已收藏",
            "取消收藏": "取消收藏",
            "正在刷新...": "正在刷新...",
            "刷新成功": "刷新成功",
            "刷新失败": "刷新失败",
            "正在切换单位...": "正在切换单位...",
            "单位已切换": "单位已切换",
            "每秒更新": "每%@秒更新",
            "选择价格单位": "选择价格单位"
        ],
        .en: [
            "设置": "Settings",
            "语言": "Language",
            "价格单位": "Price Unit",
            "搜索币种": "Search Currency",
            "自动刷新间隔": "Auto Refresh",
            "状态栏轮播间隔": "Status Bar Interval",
            "API 数据源": "API Source",
            "Powered by Binance": "Powered by Binance",
            "CoinMarket": "CoinMarket",
            "更新:": "Updated:",
            "加载中...": "Loading...",
            "加载失败": "Load failed",
            "重试": "Retry",
            "未找到相关币种": "No results found",
            "请尝试其他搜索词": "Try a different search term",
            "搜索币种...": "Search coins...",
            "我的收藏": "My Favorites",
            "暂无收藏": "No favorites yet",
            "点击货币旁的星标添加收藏": "Tap the star to add favorites",
            "打开主窗口": "Open main window",
            "价格单位:": "Price:",
            "已收藏": "Added",
            "取消收藏": "Removed",
            "正在刷新...": "Refreshing...",
            "刷新成功": "Refreshed",
            "刷新失败": "Refresh failed",
            "正在切换单位...": "Switching currency...",
            "单位已切换": "Currency switched",
            "每秒更新": "Update every %@s",
            "选择价格单位": "Select Currency"
        ],
        .ja: [
            "设置": "設定",
            "语言": "言語",
            "价格单位": "価格単位",
            "搜索币种": "コイン検索",
            "自动刷新间隔": "自動更新間隔",
            "状态栏轮播間隔": "ステータスバー更新間隔",
            "API 数据源": "API データソース",
            "Powered by Binance": "Powered by Binance",
            "CoinMarket": "CoinMarket",
            "更新:": "更新:",
            "加载中...": "読み込み中...",
            "加载失败": "読み込み失敗",
            "重试": "再試行",
            "未找到相关币种": "結果が見つかりません",
            "请尝试其他搜索词": "別の検索語を試してください",
            "搜索币种...": "コインを検索...",
            "我的收藏": "お気に入り",
            "暂无收藏": "お気に入りはまだありません",
            "点击货币旁的星标添加收藏": "星マークでお気に入りに追加",
            "打开主窗口": "メインウィンドウを開く",
            "价格单位:": "価格:",
            "已收藏": "追加済み",
            "取消收藏": "削除済み",
            "正在刷新...": "更新中...",
            "刷新成功": "更新完了",
            "刷新失败": "更新失敗",
            "正在切换单位...": "通貨単位を変更中...",
            "单位已切换": "通貨単位を変更しました",
            "每秒更新": "%@秒ごとに更新",
            "選択価格単位": "通貨を選択",
            "选择价格单位": "通貨を選択"
        ],
        .ko: [
            "设置": "설정",
            "语言": "언어",
            "价格单位": "가격 단위",
            "搜索币种": "코인 검색",
            "自动刷新间隔": "자동 새로고침 간격",
            "状态栏轮播间隔": "상태 표시줄 간격",
            "API 数据源": "API 데이터 소스",
            "Powered by Binance": "Powered by Binance",
            "CoinMarket": "CoinMarket",
            "更新:": "업데이트:",
            "加载中...": "로딩 중...",
            "加载失败": "로딩 실패",
            "重试": "다시 시도",
            "未找到相关币种": "결과 없음",
            "请尝试其他搜索词": "다른 검색어를 시도해 보세요",
            "搜索币种...": "코인 검색...",
            "我的收藏": "내 즐겨찾기",
            "暂无收藏": "아직 즐겨찾기가 없습니다",
            "点击货币旁的星标添加收藏": "별표를 눌러 즐겨찾기에 추가",
            "打开主窗口": "메인 창 열기",
            "价格单位:": "가격:",
            "已收藏": "추가됨",
            "取消收藏": "삭제됨",
            "正在刷新...": "새로고침 중...",
            "刷新成功": "새로고침 완료",
            "刷新失败": "새로고침 실패",
            "正在切换单位...": "통화 변경 중...",
            "单位已切换": "통화 변경됨",
            "每秒更新": "%@초마다 업데이트",
            "选择价格单位": "통화 선택"
        ],
        .vi: [
            "设置": "Cài đặt",
            "语言": "Ngôn ngữ",
            "价格单位": "Đơn vị giá",
            "搜索币种": "Tìm coin",
            "自动刷新间隔": "Tự động làm mới",
            "状态栏轮播间隔": "Thanh trạng thái",
            "API 数据源": "Nguồn API",
            "Powered by Binance": "Powered by Binance",
            "CoinMarket": "CoinMarket",
            "更新:": "Cập nhật:",
            "加载中...": "Đang tải...",
            "加载失败": "Tải thất bại",
            "重试": "Thử lại",
            "未找到相关币种": "Không tìm thấy",
            "请尝试其他搜索词": "Thử từ khóa khác",
            "搜索币种...": "Tìm coin...",
            "我的收藏": "Yêu thích",
            "暂无收藏": "Chưa có yêu thích",
            "点击货币旁的星标添加收藏": "Nhấn sao để thêm",
            "打开主窗口": "Mở cửa sổ chính",
            "价格单位:": "Giá:",
            "已收藏": "Đã thêm",
            "取消收藏": "Đã xóa",
            "正在刷新...": "Đang làm mới...",
            "刷新成功": "Đã làm mới",
            "刷新失败": "Lỗi làm mới",
            "正在切换单位...": "Đang đổi tiền tệ...",
            "单位已切换": "Đã đổi tiền tệ",
            "每秒更新": "Cập nhật mỗi %@ giây",
            "选择价格单位": "Chọn tiền tệ"
        ]
    ]
    
    func t(_ key: String) -> String {
        let lang = settings.language
        return translations[lang]?[key] ?? translations[.zh]?[key] ?? key
    }
    
    func t(_ key: String, _ argument: String) -> String {
        let template = t(key)
        return template.replacingOccurrences(of: "%@", with: argument)
    }
}

extension String {
    var localized: String {
        LocalizationManager.shared.t(self)
    }
    
    func localized(_ argument: String) -> String {
        LocalizationManager.shared.t(self, argument)
    }
}
