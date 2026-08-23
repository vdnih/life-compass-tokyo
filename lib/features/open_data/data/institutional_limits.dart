import '../domain/data_source.dart';
import '../domain/institutional_limit.dart';
import '../domain/institutional_scope.dart';

/// 制度上限（B1）の一元マスタ。
///
/// PDR-008: 「制度上の上限値のみ、出典付きで可視化する」の実装対象。
/// PDR-009: 実施主体（`InstitutionalScope`）と出典URLへのリンク導線を追加。
/// 実行時に外部データへアクセスせず、開発時に抽出した値を静的な Dart 定数として
/// 組み込む（PDR-006 の判断を踏襲）。
///
/// 各エントリの `catalogId` は `PredefinedCatalogRegistry.findById` で解決できる
/// ことをテスト（`institutional_limits_test.dart`）で保証する。
/// 同テストで `source.url` が全エントリで non-null であることも保証する
/// （出典リンクを常に開けるようにするため。PDR-009）。
const List<InstitutionalLimit> institutionalLimits = [
  InstitutionalLimit(
    id: 'IL-childcare-leave',
    catalogId: 'childcare-leave',
    kind: InstitutionalLimitKind.duration,
    limitMonths: 24,
    scope: InstitutionalScope.national,
    message: '育児休業は、保育所に入れないなどの事情がある場合、'
        'お子さんが2歳になるまで延長できます。',
    source: DataSource(
      name: '育児・介護休業法（第5条）',
      publisher: '厚生労働省',
      url: 'https://www.mhlw.go.jp/seisakunitsuite/bunya/koyou_roudou/'
          'koyoukintou/ryouritsu/ikuji/childcare/',
      license: '該当なし（公的な法令情報）',
    ),
  ),
  InstitutionalLimit(
    id: 'IL-maternity-leave',
    catalogId: 'maternity-leave',
    kind: InstitutionalLimitKind.duration,
    limitMonths: 4,
    scope: InstitutionalScope.national,
    message: '産前産後休業は、労働基準法により産前6週間・産後8週間の枠があります。',
    source: DataSource(
      name: '労働基準法（第65条）',
      publisher: '厚生労働省',
      url: 'https://www.bosei-navi.mhlw.go.jp/ninshin/sanzen_sango.html',
      license: '該当なし（公的な法令情報）',
    ),
  ),
  InstitutionalLimit(
    id: 'IL-postpartum-care',
    catalogId: 'childbirth',
    kind: InstitutionalLimitKind.window,
    limitMonths: 12,
    scope: InstitutionalScope.national,
    message: '産後ケア事業は、出産から1年を経過するまでの間に利用できます'
        '（母子保健法 第17条の2）。実施はお住まいの区市町村です。',
    source: DataSource(
      name: '母子保健法（第17条の2）「産後ケア事業」',
      publisher: 'こども家庭庁',
      url: 'https://sukoyaka21.cfa.go.jp/sango-care/guide_01/',
      license: '該当なし（公的な法令情報）',
    ),
  ),
  InstitutionalLimit(
    id: 'IL-paternity-leave',
    catalogId: 'childbirth',
    kind: InstitutionalLimitKind.window,
    limitMonths: 2,
    scope: InstitutionalScope.national,
    message: '産後パパ育休は、出生後8週間以内に4週間まで、'
        '2回に分割して取得できます。',
    source: DataSource(
      name: '育児・介護休業法「産後パパ育休（出生時育児休業）」',
      publisher: '厚生労働省',
      url: 'https://www.mhlw.go.jp/seisakunitsuite/bunya/koyou_roudou/'
          'koyoukintou/ryouritsu/ikuji/paternity/',
      license: '該当なし（公的な法令情報）',
    ),
  ),
  InstitutionalLimit(
    id: 'IL-overtime-limit',
    catalogId: 'childbirth',
    kind: InstitutionalLimitKind.window,
    limitMonths: 72,
    scope: InstitutionalScope.national,
    message: '所定外労働の制限（残業免除）と時間外労働の制限は、'
        '小学校就学の始期に達するまで請求できます。',
    source: DataSource(
      name: '育児・介護休業法（第16条の8・第17条）',
      publisher: '厚生労働省',
      url: 'https://www.mhlw.go.jp/seisakunitsuite/bunya/koyou_roudou/'
          'koyoukintou/ryouritsu/ikuji/unscheduled/',
      license: '該当なし（公的な法令情報）',
    ),
  ),
  InstitutionalLimit(
    id: 'IL-child-nursing-leave',
    catalogId: 'childbirth',
    kind: InstitutionalLimitKind.window,
    limitMonths: 108,
    scope: InstitutionalScope.national,
    message: '子の看護等休暇は、小学校3年生の修了まで取得できます。',
    source: DataSource(
      name: '育児・介護休業法（第16条の2）',
      publisher: '厚生労働省',
      url: 'https://www.mhlw.go.jp/seisakunitsuite/bunya/koyou_roudou/'
          'koyoukintou/ryouritsu/ikuji/nursing/',
      license: '該当なし（公的な法令情報）',
    ),
  ),
  InstitutionalLimit(
    id: 'IL-short-working-hours',
    catalogId: 'return-to-work',
    kind: InstitutionalLimitKind.window,
    limitMonths: 36,
    scope: InstitutionalScope.national,
    message: '短時間勤務等の措置は、子が3歳になるまで利用できます。',
    source: DataSource(
      name: '育児・介護休業法（第23条）',
      publisher: '厚生労働省',
      url: 'https://www.mhlw.go.jp/seisakunitsuite/bunya/koyou_roudou/'
          'koyoukintou/ryouritsu/ikuji/shortworking/',
      license: '該当なし（公的な法令情報）',
    ),
  ),
  // 東京都子育て支援制度レジストリ（t000029d0000000034）のスナップショット
  // （データ時点 2025-08-20）では、この制度の申請期限は「検査開始日から
  // 1年以内」・年齢要件は「妻43歳未満」だった。同レジストリは国のレジストリ
  // 公開に伴い更新を終了しているため、東京都福祉局の公式ページ（申請期限
  // 「検査開始日から2年以内」・年齢要件「妻40歳未満」、2026-08-23 確認）を
  // 出典に採用する。年齢要件（PDR-008 の B2）は message に含めず、対象か
  // どうかの判断は出典リンク先に委ねる。
  InstitutionalLimit(
    id: 'IL-tokyo-fertility-test-subsidy',
    catalogId: 'fertility-treatment',
    kind: InstitutionalLimitKind.window,
    limitMonths: 24,
    scope: InstitutionalScope.tokyo,
    message: '不妊検査等助成事業は、検査開始日から2年以内に申請できます。',
    source: DataSource(
      name: '東京都不妊検査等助成事業',
      publisher: '東京都福祉局',
      url: 'https://www.fukushi.metro.tokyo.lg.jp/kodomo/kosodate/josei/'
          'funinkensa/gaiyou.html',
      retrievedOn: '2026-08-23',
      license: '該当なし（公的な制度情報）',
    ),
  ),
];
