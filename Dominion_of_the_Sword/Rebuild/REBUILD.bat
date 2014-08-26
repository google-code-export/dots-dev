REM Creating datasets...
g2dc.exe
REM Merging datasets...
tfm.exe
REM descr_sm_factions.txt
dots_replicator.exe templates\RAW_descr_sm_factions.txt "..\data\descr_sm_factions.txt" DATASET.yaml
REM descr_names.txt & /text/names.txt
dots_replicator.exe -p? templates\RAW_descr_names.txt templates\SUP_descr_names.txt DATASET.yaml
dots_replicator.exe templates\SUP_descr_names.txt "..\data\descr_names.txt" DATASET.yaml
dots_replicator.exe -p? templates\text\RAW_names.txt templates\text\SUP_names.txt DATASET.yaml -i utf-16le -o utf-16le
dots_replicator.exe templates\text\SUP_names.txt "..\data\text\names.txt" DATASET.yaml -i utf-16le -o utf-16le
del templates\text\SUP_names.txt
del templates\SUP_descr_names.txt
REM export_descr_ancillaries.txt & /text/export_ancillaries.txt
dots_replicator.exe templates\RAW_export_descr_ancillaries.txt "..\data\export_descr_ancillaries.txt" DATASET.yaml
dots_replicator.exe templates\text\RAW_export_ancillaries.txt "..\data\text\export_ancillaries.txt" DATASET.yaml -i utf-16le -o utf-16le
REM export_descr_character_traits.txt & /text/export_VnVs.txt
dots_replicator.exe -p? templates\RAW_export_descr_character_traits.txt templates\SUP_export_descr_character_traits.txt DATASET.yaml
dots_replicator.exe templates\SUP_export_descr_character_traits.txt "..\data\export_descr_character_traits.txt" DATASET.yaml
dots_replicator.exe templates\text\RAW_export_VnVs.txt "..\data\text\export_VnVs.txt" DATASET.yaml -i utf-16le -o utf-16le
del templates\SUP_export_descr_character_traits.txt
REM /world/maps/base/descr_regions.txt & /text/imperial_campaign_regions_and_settlement_names.txt
dots_replicator.exe templates\world\maps\base\RAW_descr_regions.txt "..\data\world\maps\base\descr_regions.txt" DATASET.yaml
dots_replicator.exe templates\text\RAW_imperial_campaign_regions_and_settlement_names.txt "..\data\text\imperial_campaign_regions_and_settlement_names.txt" DATASET.yaml -i utf-16le -o utf-16le
del ..\data\world\maps\base\map.rwm
REM descr_rebel_factions.txt & /text/rebel_faction_descr.txt
dots_replicator.exe templates\RAW_descr_rebel_factions.txt "..\data\descr_rebel_factions.txt" DATASET.yaml
dots_replicator.exe templates\text\RAW_rebel_faction_descr.txt "..\data\text\rebel_faction_descr.txt" DATASET.yaml -i utf-16le -o utf-16le
REM world/maps/campaign/imperial_campaign/descr_events.txt & /text/historic_events.txt
dots_replicator.exe templates\world\maps\campaign\imperial_campaign\RAW_descr_events.txt "..\data\world\maps\campaign\imperial_campaign\descr_events.txt" DATASET.yaml
dots_replicator.exe templates\text\RAW_historic_events.txt "..\data\text\historic_events.txt" DATASET.yaml  -i utf-16le -o utf-16le
REM world/maps/campaign/imperial_campaign/descr_strat.txt
dots_replicator.exe -p? templates\world\maps\campaign\imperial_campaign\RAW_descr_strat.txt templates\world\maps\campaign\imperial_campaign\SUP_descr_strat.txt DATASET.yaml
dots_replicator.exe -p@ templates\world\maps\campaign\imperial_campaign\SUP_descr_strat.txt "..\data\world\maps\campaign\imperial_campaign\descr_strat.txt" DATASET.yaml
del templates\world\maps\campaign\imperial_campaign\SUP_descr_strat.txt
REM /world/maps/campaign/imperial_campaign/campaign_script.txt
dots_replicator.exe -p? templates\world\maps\campaign\imperial_campaign\RAW_psf_script.txt templates\world\maps\campaign\imperial_campaign\SUP_psf_script.txt DATASET.yaml
dots_replicator.exe templates\world\maps\campaign\imperial_campaign\SUP_psf_script.txt merge\psf_script.txt DATASET.yaml
del templates\world\maps\campaign\imperial_campaign\SUP_psf_script.txt
REM export_descr_unit.txt (EDU) & /text/export_units.txt
REM dots_replicator.exe templates\RAW_export_descr_unit.txt "..\data\export_descr_unit.txt" DATASET.yaml
dots_replicator.exe templates\text\RAW_export_units.txt "..\data\text\export_units.txt" DATASET.yaml -i utf-16le -o utf-16le
REM /unit_models/battle_models.modeldb
dots_replicator.exe templates\unit_models\RAW_battle_models_header.txt merge\modeldb\header.txt DATASET.yaml
dots_replicator templates\unit_models\RAW_battle_models.txt modeldb_prefinal.txt DATASET.yaml
ModeldbFinisher.exe
del modeldb_prefinal.txt
REM descr_banners_new.xml
dots_replicator.exe templates\RAW_descr_banners_new.xml.txt "..\data\descr_banners_new.xml" DATASET.yaml
REM descr_character.txt & descr_model_strat.txt
dots_replicator.exe -p? templates\RAW_descr_character.txt templates\SUP_descr_character.txt DATASET.yaml
dots_replicator.exe -p@ templates\SUP_descr_character.txt "..\data\descr_character.txt" DATASET.yaml
dots_replicator.exe templates\RAW_descr_model_strat.txt "..\data\descr_model_strat.txt" DATASET.yaml
del templates\SUP_descr_character.txt
REM descr_lbc_gd.txt & descr_offmap_models.txt
dots_replicator.exe templates\RAW_descr_lbc_db.txt "..\data\descr_lbc_db.txt" DATASET.yaml
dots_replicator.exe templates\RAW_descr_offmap_models.txt "..\data\descr_offmap_models.txt" DATASET.yaml
REM descr_cultures.txt
dots_replicator.exe templates\RAW_descr_cultures.txt "..\data\descr_cultures.txt" DATASET.yaml
REM descr_religions.txt & /text/religions.txt
dots_replicator.exe templates\RAW_descr_religions.txt "..\data\descr_religions.txt" DATASET.yaml
dots_replicator.exe templates\text\RAW_religions.txt "..\data\text\religions.txt" DATASET.yaml -i utf-16le -o utf-16le
REM export_descr_buildings.txt (EDB) & /text/export_buildings.txt & descr_building_battle.txt & /text/building_battle.txt
dots_replicator.exe -p? templates\RAW_export_descr_buildings.txt templates\SUP_export_descr_buildings.txt DATASET.yaml
dots_replicator.exe templates\SUP_export_descr_buildings.txt templates\SUP1_export_descr_buildings.txt DATASET.yaml
dots_replicator.exe -p@ templates\SUP1_export_descr_buildings.txt "..\data\export_descr_buildings.txt" DATASET.yaml
dots_replicator.exe -p? templates\text\RAW_export_buildings.txt templates\text\SUP_export_buildings.txt DATASET.yaml -i utf-16le -o utf-16le
dots_replicator.exe templates\text\SUP_export_buildings.txt "..\data\text\export_buildings.txt" DATASET.yaml -i utf-16le -o utf-16le
dots_replicator.exe templates\RAW_descr_building_battle.txt "..\data\descr_building_battle.txt" DATASET.yaml
dots_replicator.exe templates\text\RAW_building_battle.txt "..\data\text\building_battle.txt" DATASET.yaml -i utf-16le -o utf-16le
del templates\SUP_export_descr_buildings.txt
del templates\SUP1_export_descr_buildings.txt
del templates\text\SUP_export_buildings.txt
REM descr_sm_resources.txt
dots_replicator.exe templates\RAW_descr_sm_resources.txt "..\data\descr_sm_resources.txt" DATASET.yaml
REM descr_missions.txt & /text/missions.txt
dots_replicator.exe templates\RAW_descr_missions.txt "..\data\descr_missions.txt" DATASET.yaml
dots_replicator.exe templates\text\RAW_missions.txt "..\data\text\missions.txt" DATASET.yaml  -i utf-16le -o utf-16le
REM export_descr_guilds.txt
dots_replicator.exe templates\RAW_export_descr_guilds.txt "..\data\export_descr_guilds.txt" DATASET.yaml
REM /world/maps/campaign/imperial_campaign/descr_mercenaries.txt
dots_replicator.exe templates\world\maps\campaign\imperial_campaign\RAW_descr_mercenaries.txt templates\world\maps\campaign\imperial_campaign\SUP_descr_mercenaries.txt DATASET.yaml
dots_replicator.exe -p? templates\world\maps\campaign\imperial_campaign\SUP_descr_mercenaries.txt "..\data\world\maps\campaign\imperial_campaign\descr_mercenaries.txt" DATASET.yaml
del templates\world\maps\campaign\imperial_campaign\SUP_descr_mercenaries.txt
REM /world/maps/campaign/imperial_campaign/descr_win_conditions.txt
dots_replicator.exe templates\world\maps\campaign\imperial_campaign\RAW_descr_win_conditions.txt "..\data\world\maps\campaign\imperial_campaign\descr_win_conditions.txt" DATASET.yaml
REM /text/quotes.txt & /text/shared.txt & /text/tooltips.txt & /text/strat.txt & /text/expanded.txt
dots_replicator.exe templates\text\RAW_quotes.txt "..\data\text\quotes.txt" DATASET.yaml -i utf-16le -o utf-16le
dots_replicator.exe templates\text\RAW_shared.txt "..\data\text\shared.txt" DATASET.yaml -i utf-16le -o utf-16le
dots_replicator.exe templates\text\RAW_tooltips.txt "..\data\text\tooltips.txt" DATASET.yaml -i utf-16le -o utf-16le
dots_replicator.exe templates\text\RAW_strat.txt "..\data\text\strat.txt" DATASET.yaml -i utf-16le -o utf-16le
dots_replicator.exe templates\text\RAW_expanded.txt "..\data\text\expanded.txt" DATASET.yaml -i utf-16le -o utf-16le
REM Merging outputs.
ren TFM_config.cfg TFM_config_.cfg
ren TFM_config_output.cfg TFM_config.cfg
tfm.exe
ren TFM_config.cfg TFM_config_output.cfg
ren TFM_config_.cfg TFM_config.cfg
