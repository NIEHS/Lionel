# read and clean data from "inst/Result.csv"
# data were obtained from the water quality portal

# National Water Quality Monitoring Council, 2025, Water Quality Portal, accessed 06, 16, 2025,
#https://www.waterqualitydata.us/beta/#countrycode=US&statecode=US%3A01&siteType=Well&sampleMedia=Water&characteristicType=Nutrient&mimeType=csv&dataProfile=fullPhysChem&providers=NWIS&providers=STORET,
# https://doi.org/10.5066/P9QRKUVJ.

#

get_clean_nutrients <- function(file) {
  nutrients_data_raw <- read.csv(file)

  nutrients <- nutrients_data_raw %>%
    clean_names() %>%
    select(
      -project_name,
      -project_qapp_approved,
      -project_qapp_approval_agency,
      -project_attachment_file_name,
      -project_attachment_file_type,
      -location_state,
      -location_country_name,
      -location_country_code,
      -location_state_postal_code,
      -location_county_code,
      -location_tribal_land_indicator, # all NA
      -location_tribal_land, # all NA
      -alternate_location_identifier_count,
      -activity_activity_identifier_user_supplied, # all NA
      -activity_media, # all water besides row 186
      -activity_bottom_depth_sampling_component, # all NA
      -activity_biological_assemblage_sampled, # all NA
      -activity_biological_toxicity_test_type, # all NA
      -activity_location_longitude,
      -activity_location_latitude,
      -activity_location_horz_coord_reference_system_datum, # all NA
      -activity_location_source_map_scale, # all NA
      -activity_location_latitude_standardized, # all NA
      -activity_location_longitude_standardized, # all NA
      -activity_location_horz_coord_standardized_datum, # all NA
      -activity_location_horz_accuracy_measure, # all NA
      -activity_location_horz_accuracy_measure_unit, # all NA
      -activity_location_horizontal_accuracy_horz_collection_method, # all NA
      -activity_location_description, # all NA
      -activity_end_date, # all NA
      -activity_end_time, # all NA
      -activity_end_time_zone, # all NA
      -activity_activity_relative_depth, # all NA
      -activity_top_depth_measure, # all NA
      -activity_bottom_depth_measure, # all NA
      -activity_bottom_depth_measure_unit, # all NA
      -sample_collection_method_qualifier_type_name, # all NA
      -sample_collection_method_equipment_comment, # all NA
      -sample_prep_method_identifier, # all NA
      -sample_prep_method_identifier_context, # all NA
      -sample_prep_method_name, # all NA
      -sample_prep_method_qualifier_type, # all NA
      -sample_prep_method_description, # all NA
      -sample_prep_method_container_label, # all NA
      -sample_prep_method_container_type, # all NA
      -sample_prep_method_container_color, # all NA
      -sample_prep_method_chemical_preservative_used, # all NA
      -sample_prep_method_thermal_preservative_used, # all NA
      -sample_prep_method_transport_storage_description, # all NA
      -activity_attachment_file_name, # all NA
      -activity_attachment_file_type, # all NA
      -activity_attachment_file_download, # all NA
      -result_data_logger_line, # all NA
      -result_biological_intent, # all NA
      -result_biological_individual_identifier, # all NA
      -result_biological_taxon, # all NA
      -result_biological_taxon_user_supplied, # all NA
      -result_biological_taxon_user_supplied_reference, # all NA
      -result_biological_unidentified_species_identifier, # all NA
      -result_biological_sample_tissue_anatomy, # all NA
      -result_biological_group_summary_count, # all NA
      -group_summary_weight_measure, # all NA
      -group_summary_weight_measure_unit, # all NA
      -result_depth_height_measure, # all NA
      -result_depth_height_measure_unit, # all NA
      -result_depth_height_altitude_reference_point, # all NA
      -result_depth_height_sampling_point_name, # all NA
      -result_depth_height_sampling_point_type, # all NA
      -result_depth_height_sampling_point_place_in_series, # all NA
      -result_depth_height_sampling_point_comment, # all NA
      -result_depth_height_record_identifier_user_supplied, # all NA
      -result_statistical_base, # all NA
      -result_statistical_n_value, # all NA
      -result_weight_basis, # all NA
      -result_weight_basis, # all NA
      -result_time_basis, # all NA
      -result_measure_temperature_basis, # all NA
      -result_measure_particle_size_basis, # all NA
      -data_quality_precision_value, # all NA
      -data_quality_bias_value, # all NA
      -data_quality_confidence_interval_value, # all NA
      -data_quality_upper_confidence_limit_value, # all NA
      -data_quality_lower_confidence_limit_value, # all NA
      -lab_info_lab_sample_split_ratio, # all NA
      -lab_info_lab_accreditation_indicator, # all NA
      -lab_info_lab_accreditation_authority, # all NA
      -lab_info_taxon_accreditation_indicator, # all NA
      -lab_info_taxon_accreditation_authority, # all NA
      -result_comparable_method_identifier, # all NA
      -result_comparable_method_identifier_context, # all NA
      -result_comparable_method_modification, # all NA
      -lab_info_analysis_end_date, # all NA
      -lab_info_analysis_end_time, # all NA
      -lab_info_analysis_end_time_zone, # all NA
      -lab_sample_prep_method_identifier, # all NA
      -lab_sample_prep_method_identifier_context, # all NA
      -lab_sample_prep_method_name, # all NA
      -lab_sample_prep_method_qualifier_type, # all NA
      -lab_sample_prep_method_description, # all NA
      -lab_sample_prep_method_start_date, # all NA
      -lab_sample_prep_method_start_time, # all NA
      -lab_sample_prep_method_start_time_zone, # all NA
      -lab_sample_prep_method_end_date, # all NA
      -lab_sample_prep_method_end_time, # all NA
      -lab_sample_prep_method_end_time_zone, # all NA
      -lab_sample_prep_method_dilution_factor, # all NA
      -result_attachment_file_name, # all NA
      -result_attachment_file_type, # all NA
      -result_attachment_file_download, # all NA
      -result_characteristic_group, # all nutrient besides row 186
      -org_type
    )

  nutrients
}
