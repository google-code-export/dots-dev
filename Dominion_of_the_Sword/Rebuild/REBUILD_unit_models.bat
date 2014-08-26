REM Creating datasets...
g2dc.exe
REM Merging datasets...
tfm.exe
REM /unit_models/battle_models.modeldb
dots_replicator.exe templates\unit_models\RAW_battle_models_header.txt merge\modeldb\header.txt DATASET.yaml
dots_replicator templates\unit_models\RAW_battle_models.txt modeldb_prefinal.txt DATASET.yaml
ModeldbFinisher.exe
del modeldb_prefinal.txt
REM Merging outputs.
ren TFM_config.cfg TFM_config_.cfg
ren TFM_config_modeldb.cfg TFM_config.cfg
tfm.exe
ren TFM_config.cfg TFM_config_modeldb.cfg
ren TFM_config_.cfg TFM_config.cfg