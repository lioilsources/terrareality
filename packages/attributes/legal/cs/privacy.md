---
title: Zásady ochrany osobních údajů
version: 2026-10
draft: true
---

> **PRACOVNÍ NÁVRH k právní revizi.** Text není platný, dokud jej neschválí právník provozovatele a pověřenec pro ochranu osobních údajů. Hodnoty v hranatých závorkách je nutné doplnit.

## 1. Správce

Správcem osobních údajů je [obchodní firma], IČO [doplnit], se sídlem [adresa] (dále jen „provozovatel“), e-mail [soukromi@terrareality.cz].

Pověřenec pro ochranu osobních údajů (DPO): [jméno / externí DPO], e-mail [dpo@terrareality.cz]. [Ověřit, zda je jmenování DPO povinné, viz Q-GDPR-6.]

Pronajímatel, který na platformě vede své nájmy, je pro údaje svých nájemníků samostatným správcem; provozovatel je v tomto rozsahu jeho zpracovatelem podle smlouvy o zpracování, která je součástí podmínek pro pronajímatele. [Ověřit rozdělení rolí.]

## 2. Jaké údaje zpracováváme a proč

- **Účet:** e-mail, jméno, heslo (jen otisk), jazyk, telefon (volitelně). Účel: poskytování služby. Právní základ: plnění smlouvy (čl. 6 odst. 1 písm. b GDPR).
- **Ověření totožnosti přes BankID:** jméno, datum narození, adresa, úroveň ověření. Účel: důvěryhodnost stran a uzavření smlouvy. Právní základ: plnění smlouvy a oprávněný zájem na prevenci podvodů.
- **Inzeráty, fotografie, zprávy, žádosti, prohlídky, smlouvy:** obsah, který uživatelé vytvoří. Účel: poskytování služby. Právní základ: plnění smlouvy.
- **Platby a bankovní transakce pronajímatele (čtení přes GoCardless):** protistrana, částka, variabilní symbol, datum. Účel: párování plateb s předpisy. Právní základ: plnění smlouvy s pronajímatelem a jeho oprávněný zájem.
- **Hodnocení rizika nájmu:** platební chování, údaje z Tenant Passportu, lokalita. Účel: informace pro pronajímatele; **nikdy nerozhoduje automaticky**. Právní základ: oprávněný zájem pronajímatele. [Ověřit profilování, viz Q-RISK-1.]
- **Fakturace placených služeb:** fakturační údaje, platby kartou (karta zpracovává Stripe, provozovatel číslo karty nevidí). Právní základ: plnění smlouvy a právní povinnost (účetnictví, DPH).
- **Bezpečnost a provoz:** IP adresa, prohlížeč, záznamy o přihlášení, auditní záznamy, diagnostika chyb. Právní základ: oprávněný zájem na bezpečnosti.
- **Souhlasy:** verze podmínek a zásad, se kterou uživatel souhlasil, a čas souhlasu. Právní základ: právní povinnost prokázat souhlas.

## 3. Umělá inteligence

Návrhy AI (texty, atributy z fotografií, shrnutí, moderační upozornění) počítáme primárně na vlastním serveru provozovatele (DGX Spark) v České republice; data neopouštějí infrastrukturu provozovatele. Pokud je vlastní server nedostupný a provozovatel zapne záložní režim, mohou být jednotlivé požadavky zpracovány cloudovým poskytovatelem jazykového modelu (Anthropic Claude, přes cloudovou bránu [doplnit provozovatele brány]) [ověřit umístění zpracování a předání do třetích zemí, viz Q-AI-1]. Výstupy AI jsou vždy jen návrhy, které schvaluje člověk.

## 4. Příjemci a zpracovatelé

| Příjemce | Role | Účel | Umístění |
| --- | --- | --- | --- |
| Hetzner Online GmbH | zpracovatel | hosting, databáze, zálohy, úložiště fotografií | EU (DE/FI) |
| Provozovatel – vlastní server DGX Spark | provozovatel sám | výpočty AI | ČR |
| Bankovní identita, a.s. (BankID) | samostatný správce / zpracovatel [ověřit] | ověření totožnosti, podpis | ČR |
| GoCardless (Bank Account Data) | zpracovatel | čtení transakcí pronajímatele (AIS) | EU/UK [ověřit] |
| Stripe Payments Europe, Ltd. | samostatný správce / zpracovatel | platby kartou za propagaci, předplatné | EU, USA (SCC) |
| Revolut Bank UAB | samostatný správce | platební odkazy na účtu pronajímatele | EU |
| Poskytovatel e-mailu [doplnit] | zpracovatel | odesílání e-mailů | [doplnit] |
| Google, Apple | samostatní správci | přihlášení účtem Google/Apple, push notifikace (Firebase) | EU, USA (DPF/SCC) |
| Sentry [doplnit, pokud SaaS] | zpracovatel | diagnostika chyb aplikací | [doplnit] |
| Anthropic (jen záložní režim AI) | zpracovatel | záložní výpočty AI | USA (SCC/DPF) [ověřit] |
| OpenFreeMap | — | mapové podklady (dostává IP adresu prohlížeče) | EU [ověřit] |
| Orgány veřejné moci | samostatní správci | na základě zákonné povinnosti | ČR/EU |

Údaje inzerátů jsou veřejné. Údaje žadatele vidí pronajímatel, jehož inzerátu se žádost týká, až v rozsahu, který žadatel sdílí.

## 5. Doba uchování

- Účet: po dobu existence účtu; výmaz proběhne 30 dní po žádosti (lhůtu lze zrušit), poté pseudonymizace. [Q-GDPR-2]
- Údaje z ověření totožnosti: smazání při výmazu účtu, pokud neexistuje smlouva; jinak po dobu promlčecí lhůty (3 roky po skončení nájmu). [Q-GDPR-1]
- Zprávy: 24 měsíců od poslední zprávy, pokud nevedly k nájmu. [Q-MSG-1]
- Smlouvy a doklady: 10 let (účetní a daňové předpisy).
- Auditní a bezpečnostní záznamy: 3 roky. [Q-GDPR-5]
- Zálohy: [doplnit, např. 30 dní], poté přepsání.

## 6. Vaše práva

Máte právo na přístup, opravu, výmaz, omezení zpracování, přenositelnost (export dat v nastavení účtu), právo vznést námitku proti zpracování na základě oprávněného zájmu a právo nebýt předmětem rozhodnutí založeného výhradně na automatizovaném zpracování. Souhlas lze kdykoli odvolat. Žádosti vyřizujeme do jednoho měsíce na [soukromi@terrareality.cz] nebo přímo v nastavení účtu (export a výmaz).

Máte právo podat stížnost u Úřadu pro ochranu osobních údajů (www.uoou.cz).

## 7. Zabezpečení

Data jsou šifrována při přenosu (TLS) a citlivé údaje i v klidu; přístup zaměstnanců je omezen rolí a auditován; zálohy jsou šifrované a pravidelně testované.

## 8. Cookies

Používáme jen nezbytné cookies, viz [Zásady používání cookies](/cookies).

Účinnost od: [doplnit].
