/// 制度の実施主体（PDR-009）。
///
/// 「自分が対象になるか」の気づきを得るための最低限の分類として、
/// 国か東京都かの2値のみを持つ。区市町村単位のラベルは作らない
/// （実施主体が区市町村の制度でも、根拠法令が国の法律であれば `national`
/// とし、実施主体である旨は `InstitutionalLimit.message` に含める）。
enum InstitutionalScope {
  national('国の制度'),
  tokyo('東京都の制度');

  const InstitutionalScope(this.label);
  final String label;
}
