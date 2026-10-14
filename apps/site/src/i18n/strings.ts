/** Landing page copy. Kept small and local; the web app uses Paraglide. */
export const strings = {
  cs: {
    title: 'TerraReality: pronájmy bez starostí',
    description: 'Najděte byt nebo pokoj na mapě, podepište smlouvu přes BankID a mějte přehled o nájmu.',
    hero: 'Pronájem od hledání po zaplacený nájem',
    lead: 'Mapa od kraje po ulici, chat s majitelem, digitální smlouva a hlídání plateb. Pro majitele inzerce zdarma.',
    ctaSearch: 'Hledat bydlení',
    ctaLandlord: 'Pronajmout byt',
    features: [
      ['Mapa a chat', 'Napište, co hledáte, a mapa se nastaví sama.'],
      ['Smlouva přes BankID', 'Šablony smluv revidované právníkem a podpis online.'],
      ['Platby pod kontrolou', 'QR platba a automatické párování plateb. Peníze jdou přímo majiteli.'],
      ['Spolubydlení', 'Pokoje, skupinové žádosti a dělení nájmu mezi spolubydlící.']
    ],
    switchLang: 'English'
  },
  en: {
    title: 'TerraReality: renting without the hassle',
    description: 'Find a flat or a room on the map, sign the lease with BankID and keep track of rent.',
    hero: 'Renting from search to paid rent',
    lead: 'A map from region to street, chat with the landlord, a digital lease and payment tracking. Free listings for landlords.',
    ctaSearch: 'Find a home',
    ctaLandlord: 'List a flat',
    features: [
      ['Map and chat', 'Describe what you need and the map adjusts itself.'],
      ['Lease via BankID', 'Lawyer-reviewed lease templates and online signing.'],
      ['Payments in control', 'QR payments and automatic matching. Money goes straight to the landlord.'],
      ['Co-living', 'Rooms, group applications and rent split between flatmates.']
    ],
    switchLang: 'Čeština'
  }
} as const;

export type Locale = keyof typeof strings;
