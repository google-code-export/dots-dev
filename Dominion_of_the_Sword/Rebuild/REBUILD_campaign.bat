REM Creating datasets...
g2dc.exe
REM Merging datasets...
tfm.exe
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
REM /world/maps/base/descr_regions.txt & /text/imperial_campaign_regions_and_settlement_names.txt
dots_replicator.exe templates\world\maps\base\RAW_descr_regions.txt "..\data\world\maps\base\descr_regions.txt" DATASET.yaml
dots_replicator.exe templates\text\RAW_imperial_campaign_regions_and_settlement_names.txt "..\data\text\imperial_campaign_regions_and_settlement_names.txt" DATASET.yaml -i utf-16le -o utf-16le
del ..\data\world\maps\base\map.rwm
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
REM /world/maps/campaign/imperial_campaign/descr_mercenaries.txt
dots_replicator.exe templates\world\maps\campaign\imperial_campaign\RAW_descr_mercenaries.txt templates\world\maps\campaign\imperial_campaign\SUP_descr_mercenaries.txt DATASET.yaml
dots_replicator.exe -p? templates\world\maps\campaign\imperial_campaign\SUP_descr_mercenaries.txt "..\data\world\maps\campaign\imperial_campaign\descr_mercenaries.txt" DATASET.yaml
del templates\world\maps\campaign\imperial_campaign\SUP_descr_mercenaries.txt
REM /world/maps/campaign/imperial_campaign/descr_win_conditions.txt
dots_replicator.exe templates\world\maps\campaign\imperial_campaign\RAW_descr_win_conditions.txt "..\data\world\maps\campaign\imperial_campaign\descr_win_conditions.txt" DATASET.yaml
REM Merging outputs.
ren TFM_config.cfg TFM_config_.cfg
ren TFM_config_output.cfg TFM_config.cfg
tfm.exe
ren TFM_config.cfg TFM_config_output.cfg
ren TFM_config_.cfg TFM_config.cfg
