import '../domain/data_source.dart';
import '../domain/institutional_limit.dart';

/// 制度上限（B1）の一元マスタ。
///
/// PDR-008: 「制度上の上限値のみ、出典付きで可視化する」の実装対象。
/// 実行時に外部データへアクセスせず、開発時に抽出した値を静的な Dart 定数として
/// 組み込む（PDR-006 の判断を踏襲）。
///
/// 各エントリの `catalogId` は `PredefinedCatalogRegistry.findById` で解決できる
/// ことをテスト（`institutional_limits_test.dart`）で保証する。
const List<InstitutionalLimit> institutionalLimits = [
  InstitutionalLimit(
    id: 'IL-childcare-leave',
    catalogId: 'childcare-leave',
    kind: InstitutionalLimitKind.duration,
    limitMonths: 24,
    message: '育児休業は、保育所に入れないなどの事情がある場合、'
        'お子さんが2歳になるまで延長できます。',
    source: DataSource(
      name: '育児・介護休業法（第5条）',
      publisher: '厚生労働省',
      url: 'https://www.mhlw.go.jp/stf/seisakunitsuite/bunya/koyou_roudou/'
          'koyoukintou/pamphlet/index_00006.html',
      license: '該当なし（公的な法令情報）',
    ),
  ),
  InstitutionalLimit(
    id: 'IL-maternity-leave',
    catalogId: 'maternity-leave',
    kind: InstitutionalLimitKind.duration,
    limitMonths: 4,
    message: '産前産後休業は、労働基準法により産前6週間・産後8週間の枠があります。',
    source: DataSource(
      name: '労働基準法（第65条）',
      publisher: '厚生労働省',
      url: 'https://www.mhlw.go.jp/stf/seisakunitsuite/bunya/koyou_roudou/'
          'koyoukintou/josei-katsuyaku/mokuji.html',
      license: '該当なし（公的な法令情報）',
    ),
  ),
  InstitutionalLimit(
    id: 'IL-postpartum-care',
    catalogId: 'childbirth',
    kind: InstitutionalLimitKind.window,
    limitMonths: 12,
    message: '産後ケア事業は、出産から1年を経過するまでの間に利用できます'
        '（母子保健法 第17条の2）。',
    source: DataSource(
      name: '東京デジタル2030ビジョン（こどもDX）子育て支援制度レジストリ「産後ケア事業」',
      publisher: '東京都デジタルサービス局',
      url: 'https://catalog.data.metro.tokyo.lg.jp/dataset/t000029d0000000034',
      datasetId: 't000029d0000000034',
      retrievedOn: '2026-08-23',
      license: 'CC BY 4.0',
    ),
  ),
];
