// Faktura – daňový doklad for platform services (promo products).
// Contains the particulars of § 29 odst. 1 zákona č. 235/2004 Sb., o DPH.
// Data comes from the api as JSON in sys.inputs.data; amounts and dates are
// already formatted. Open legal points: docs/legal-questions.md (Q-BILL-*).

#let data = json(bytes(sys.inputs.data))
#let opt(p, key) = p.at(key, default: "")

#set document(title: "Faktura – daňový doklad " + data.number)
#set page(paper: "a4", margin: (x: 2cm, y: 2.2cm),
  footer: context [
    #set text(8pt, fill: gray)
    Faktura – daňový doklad #data.number #h(1fr) #counter(page).display("1 / 1", both: true)
  ])
#set text(font: "Libertinus Serif", size: 10pt, lang: "cs")
#set par(leading: 0.6em)

#let party(title, p) = block(width: 100%)[
  #text(8.5pt, fill: gray, upper(title)) \
  *#p.name* \
  #if opt(p, "address") != "" [#p.address \ ]
  #if opt(p, "ico") != "" [IČO: #p.ico \ ]
  #if opt(p, "dic") != "" [DIČ: #p.dic \ ]
  #if opt(p, "email") != "" [E-mail: #p.email \ ]
]

#grid(columns: (1fr, auto), align: (left, right),
  text(18pt, weight: "bold")[Faktura – daňový doklad],
  text(12pt)[č. *#data.number*])

#v(0.6em)
#grid(columns: (1fr, 1fr), gutter: 1.5em,
  party("Dodavatel", data.supplier),
  party("Odběratel", data.buyer))

#v(0.6em)
#table(columns: (auto, 1fr), stroke: none, inset: (x: 0pt, y: 2pt), column-gutter: 1em,
  [Datum vystavení:], [#data.issued_on],
  [Datum uskutečnění zdanitelného plnění:], [#data.taxable_supply_on],
  [Datum splatnosti:], [#data.due_on],
  [Způsob úhrady:], [#data.payment_method],
  ..if data.order_ref != "" { ([Objednávka:], [#data.order_ref]) },
  ..if opt(data.supplier, "iban") != "" { ([Účet dodavatele:], [#data.supplier.iban]) },
)

#v(0.8em)
#table(
  columns: (1fr, auto, auto, auto, auto, auto, auto),
  align: (left, right, right, right, right, right, right),
  stroke: (x, y) => if y == 0 { (bottom: 0.6pt) } else { (bottom: 0.3pt + luma(200)) },
  inset: (x: 4pt, y: 5pt),
  table.header([*Popis plnění*], [*Množství*], [*Cena/ks bez DPH*], [*Sazba DPH*], [*Základ daně*], [*DPH*], [*Celkem s DPH*]),
  ..data.lines.map(l => (
    [#l.description], [#l.quantity ks], [#l.unit_net], [#l.rate], [#l.net], [#l.vat], [#l.gross],
  )).flatten(),
)

#v(0.8em)
#grid(columns: (1fr, auto), gutter: 1em,
  [],
  [
    *Rekapitulace DPH*
    #table(columns: (auto, auto, auto, auto), align: right, stroke: none, inset: (x: 6pt, y: 2pt),
      [Sazba], [Základ daně], [DPH], [Celkem],
      ..data.recap.map(r => ([#r.rate], [#r.net], [#r.vat], [#r.gross])).flatten(),
    )
    #line(length: 100%, stroke: 0.4pt)
    #table(columns: (auto, auto), align: (left, right), stroke: none, inset: (x: 6pt, y: 2pt),
      [Celkem bez DPH:], [#data.total_net],
      [DPH celkem:], [#data.total_vat],
      [*Celkem s DPH:*], [*#data.total_gross*],
      [Uhrazeno:], [#data.paid],
      [*Zbývá uhradit:*], [*#data.to_pay*],
    )
  ])

#v(1em)
#set text(9pt)
#if data.note != "" [#data.note \ ]
Částka byla uhrazena platební kartou; nehraďte prosím znovu.
