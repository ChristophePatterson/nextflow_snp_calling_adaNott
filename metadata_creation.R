library(tidyverse)

## Read in args
args <- commandArgs(trailingOnly=T)

samps <- read_table(args[1], col_names="individual")
sample_data <- read_csv(args[2], 
            col_names = c("individual","R1_read","R2_read","R0_read","Path","sum_file_size",
                        "Region","Species","Waterbody","Population","species_pair",
                        "Salinity","Ecotype","Sex","Age")) %>%
                filter(individual %in% samps$individual)

## Read in sample site data
site_data <- read_csv("/gpfs01/home/mbzcp2/data/Loch list definitive lat_lon.csv") %>%
    mutate(Waterbody = toupper(Code))

site_data[site_data$Waterbody %in% sample_data$Waterbody,]

## List of column info needed
# RepAdaptID ,sampleID, populationID, scientificName, scientificNameID, identificationRemarks, location, 
# locality, countryCode, decimalLatitude, decimalLongitude, geodeticDatum, coordinateUncertaintyInMeters, #
# verbatimDepth, locationRemarks, eventDate, generalRemarks, YOUR_trait1_units, YOUR_trait2_units, measurementRemarks

names(sample_data)
names(site_data)

# Get ISO 3166 country codes
ISO3166 <- cbind.data.frame(Region = c("Portugal", "Iceland", "Quebec", "Uist"), countryCode = c("PT","IS","CA","GB"))
# Join sample data with sample site data
sample_data <- sample_data %>%
    select(individual, Region, Waterbody, Population) %>%
    mutate(RepAdaptID = "rawg0173_Gasterosteus_aculeatus_Patterson",
            scientificName = "Gasterosteus aculeatus",
            scientificNameID = "GBIFtaxonID:4286327",
            identificationRemarks = "",
            geodeticDatum = "WGS84",
            coordinateUncertaintyInMeters = "",
            verbatimDepth = "",
            locality = "",
            locationRemarks = "",
            eventDate = "") %>%
    rename(sampleID = individual,
            populationID = Population) %>%
    left_join(site_data[,c("Waterbody", "Name", "lon", "lat")], by = "Waterbody") %>%
    rename(decimalLatitude = lat, decimalLongitude = lon,
            location = Name) %>%
    left_join(ISO3166, by = "Region") %>%
    mutate(locality = ifelse(Region == "Uist", "Scotland", "")) %>%
    select(RepAdaptID ,sampleID, populationID, scientificName, scientificNameID, identificationRemarks, location, 
            locality, countryCode, decimalLatitude, decimalLongitude, geodeticDatum, coordinateUncertaintyInMeters,
            verbatimDepth, locationRemarks, eventDate)

sample_data

sample_data %>%
    # filter(!duplicated(Population)) %>%
    write.table("RepAdapt_rawg0173_Gasterosteus_aculeatus_Patterson_metadata.txt", row.names = F, quote = F, sep = "\t")


