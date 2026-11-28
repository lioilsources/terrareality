// Package ruian imports address points from the Czech address register
// (RÚIAN) and powers address autocomplete. It lives in
// ol1n_platform_kit/ruian (ADR 0013); the tables keep their names.
package ruian

import kit "github.com/lioilsources/ol1n_platform_kit/ruian"

// OfficialAddressesURL is the ČÚZK open-data download of all address points.
const OfficialAddressesURL = kit.OfficialAddressesURL

type (
	Keep    = kit.Keep
	Region  = kit.Region
	Counter = kit.Counter
)

var (
	Sample      = kit.Sample
	PrahaSample = kit.PrahaSample
	Regions     = kit.Regions

	Import               = kit.Import
	ImportFiltered       = kit.ImportFiltered
	ImportFile           = kit.ImportFile
	ImportFileFiltered   = kit.ImportFileFiltered
	ImportRegionSample   = kit.ImportRegionSample
	SeedSample           = kit.SeedSample
	NewCounter           = kit.NewCounter
	FileMunicipalityCode = kit.FileMunicipalityCode
	DefaultExportDate    = kit.DefaultExportDate
	Download             = kit.Download
)
