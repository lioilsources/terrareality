// Shared layout and clauses of Czech residential leases (cs + en).
// DRAFT: the customer's lawyer reviews these texts before M6 acceptance
// (docs/legal-questions.md, Q-LEASE-1). Data comes from the api as JSON in
// sys.inputs.data; amounts are already formatted.

#let data = json(bytes(sys.inputs.data))

#let setup(body) = {
  set document(title: "Nájemní smlouva " + str(data.code))
  set page(paper: "a4", margin: (x: 2.2cm, y: 2.4cm),
    footer: context [
      #set text(8pt, fill: gray)
      Smlouva / Lease #data.code · #counter(page).display("1 / 1", both: true)
      #h(1fr) #data.document_id
    ],
    background: if data.draft { rotate(-40deg, text(64pt, fill: rgb(220, 38, 38, 40))[NÁVRH · DRAFT]) })
  set text(font: "Libertinus Serif", size: 10.5pt, lang: "cs")
  set par(justify: true, leading: 0.62em)
  set heading(numbering: none)
  show heading.where(level: 1): set text(15pt)
  show heading.where(level: 2): set text(11pt)
  body
}

#let t(lang, cs, en) = if lang == "cs" { cs } else { en }

#let party-block(p, lang) = [
  *#p.name*#if p.at("email", default: "") != "" [, #p.email]
  #if p.at("share_pct", default: none) != none and p.role != "landlord" [
    \ #t(lang, "podíl na platbách", "payment share"): #p.share_pct %
  ]
]

#let role-label(role, lang) = (
  landlord: t(lang, "pronajímatel", "landlord"),
  tenant: t(lang, "nájemce", "tenant"),
  co_tenant: t(lang, "společný nájemce", "joint tenant"),
  subtenant: t(lang, "podnájemce", "subtenant"),
  guarantor: t(lang, "ručitel", "guarantor"),
).at(role)

#let parties(lang) = [
  == #t(lang, "Smluvní strany", "Parties")
  #for p in data.parties [
    - #role-label(p.role, lang): #party-block(p, lang)
  ]
]

#let term(lang) = if data.ends_on == none [
  #t(lang)[Nájem se sjednává na dobu neurčitou s účinností od #data.starts_on.][The lease is concluded for an indefinite period effective from #data.starts_on.]
] else [
  #t(lang)[Nájem se sjednává na dobu určitou od #data.starts_on do #data.ends_on.][The lease is concluded for a fixed term from #data.starts_on to #data.ends_on.]
]

#let clause-text = (
  pets_allowed: ([Nájemce smí v bytě chovat domácí zvíře, pokud tím neobtěžuje ostatní uživatele domu; za škody způsobené zvířetem odpovídá nájemce.],
    [The tenant may keep a pet in the flat as long as it does not disturb other residents; the tenant is liable for damage caused by the pet.]),
  no_smoking: ([V bytě a na balkoně platí zákaz kouření.], [Smoking is prohibited in the flat and on the balcony.]),
  inventory: ([Součástí smlouvy je soupis vybavení předaný při předání bytu; nájemce vrací vybavení ve stavu odpovídajícím běžnému opotřebení.],
    [An inventory of furnishings handed over at move-in forms part of this lease; the tenant returns it in a condition reflecting normal wear and tear.]),
  indexation: ([Pronajímatel může jednou ročně zvýšit nájemné o míru inflace vyhlášenou ČSÚ za předchozí kalendářní rok, nejvýše však o 10 %.],
    [Once a year the landlord may increase the rent by the inflation rate published by the Czech Statistical Office for the previous year, by at most 10 %.]),
  sublet_forbidden: ([Podnájem bytu nebo jeho části třetí osobě je možný jen s písemným souhlasem pronajímatele.],
    [Subletting the flat or any part of it requires the landlord's written consent.]),
  early_termination: ([Nájemce může nájem na dobu určitou ukončit výpovědí s tříměsíční výpovědní dobou i bez udání důvodu.],
    [The tenant may terminate the fixed-term lease with three months' notice without giving a reason.]),
)

#let payments(lang) = [
  == #t(lang, "Nájemné, služby a kauce", "Rent, services and deposit")
  #t(lang)[Nájemné činí #data.rent měsíčně, zálohy na služby spojené s užíváním bytu #data.services měsíčně. Platby jsou splatné vždy do #data.due_day. dne kalendářního měsíce, za který se platí, na účet pronajímatele #data.payee.iban (#data.payee.name) s variabilním symbolem #data.code.][The rent is #data.rent per month and the advance payments for services are #data.services per month. Payments are due by day #data.due_day of the month they relate to, to the landlord's account #data.payee.iban (#data.payee.name), with variable symbol #data.code.]

  #if data.parties.filter(p => p.role != "landlord").len() > 1 [
    #t(lang)[Nájemci platí své podíly uvedené u smluvních stran samostatně, každý se specifickým symbolem podle svého pořadí; vůči pronajímateli však odpovídají společně a nerozdílně (§ 2270 občanského zákoníku).][The tenants pay their shares listed with the parties separately, each with the specific symbol of their position; towards the landlord they remain jointly and severally liable (section 2270 of the Civil Code).]
  ]

  #t(lang)[Nájemce složí kauci ve výši #data.deposit nejpozději v den předání bytu. Kauce nepřesahuje trojnásobek měsíčního nájemného (§ 2254 občanského zákoníku). Pronajímatel ji vrátí do 30 dnů od skončení nájmu po započtení oprávněných pohledávek, s úrokem nejméně v zákonné výši.][The tenant pays a deposit of #data.deposit no later than on the day the flat is handed over. The deposit does not exceed three months' rent (section 2254 of the Civil Code). The landlord returns it within 30 days after the lease ends, less justified claims and with interest at least at the statutory rate.]

  #t(lang)[Platby probíhají přímo mezi stranami; TerraReality platby nepřijímá ani nedrží, pouze je eviduje.][Payments are made directly between the parties; TerraReality neither receives nor holds money, it only records the payments.]
]

#let common-end(lang) = [
  == #t(lang, "Práva a povinnosti", "Rights and obligations")
  #t(lang)[Nájemce užívá byt řádně, hradí běžnou údržbu a drobné opravy (nařízení vlády č. 308/2015 Sb.) a umožní pronajímateli po předchozím ohlášení prohlídku bytu. Pronajímatel zajistí nerušené užívání bytu a služby spojené s nájmem.][The tenant uses the flat properly, pays for routine maintenance and minor repairs (Government Regulation No. 308/2015 Coll.) and lets the landlord inspect the flat after prior notice. The landlord ensures the undisturbed use of the flat and the services related to the lease.]

  #if data.clauses.len() > 0 [
    == #t(lang, "Zvláštní ujednání", "Special terms")
    #for c in data.clauses [
      - #if lang == "cs" { clause-text.at(c).at(0) } else { clause-text.at(c).at(1) }
    ]
  ]

  == #t(lang, "Skončení nájmu", "Termination")
  #t(lang)[Nájem lze ukončit dohodou nebo výpovědí z důvodů stanovených zákonem. Výpovědní doba činí #data.notice_months měsíce a počíná prvním dnem měsíce následujícího po doručení výpovědi.][The lease may end by agreement or by notice on the grounds set out by law. The notice period is #data.notice_months months and starts on the first day of the month following delivery of the notice.]

  == #t(lang, "Závěrečná ustanovení", "Final provisions")
  #t(lang)[Smlouva se řídí českým právem, zejména § 2235 a násl. občanského zákoníku. Smlouva je podepsána elektronicky; podpisy a průběh smlouvy jsou zaznamenány v auditním řetězci TerraReality (kód #data.code). V případě rozporu jazykových verzí má přednost česká verze.][This lease is governed by Czech law, in particular sections 2235 et seq. of the Civil Code. It is signed electronically; signatures and the course of the lease are recorded in the TerraReality audit chain (code #data.code). In case of discrepancy between the language versions, the Czech version prevails.]
]

#let lease(title-cs, title-en, subject-cs, subject-en) = setup[
  #for lang in ("cs", "en") [
    #if lang == "en" { pagebreak() }
    #set text(lang: lang)
    #align(center)[= #t(lang, title-cs, title-en)]
    #align(center, text(9pt, fill: gray)[#t(lang, "Kód smlouvy", "Lease code") #data.code · #data.generated_at])
    #parties(lang)
    == #t(lang, "Předmět nájmu", "Subject of the lease")
    #t(lang, subject-cs, subject-en)
    #term(lang)
    #payments(lang)
    #common-end(lang)
    #v(1.5em)
    #grid(columns: (1fr, 1fr), gutter: 2em,
      ..data.parties.map(p => [
        #line(length: 90%, stroke: 0.5pt)
        #text(9pt)[#p.name, #role-label(p.role, lang)]
      ]))
  ]
]
