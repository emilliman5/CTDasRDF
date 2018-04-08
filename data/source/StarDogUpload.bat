@echo off
REM ---------------------------------------------------------------------------
REM StarDogUpload.bat
REM Batch upload to Stardog using SMS files.
REM ---------------------------------------------------------------------------
@echo on
cd C:\_gitHub\CTDasRDF\data\source

@echo Importing DM 
call stardog-admin virtual import CTDasRDF DM_mappings.TTL DM_subset.csv

REM @echo Importing Investigator and Site (Imputed)
REM call stardog-admin virtual import CTDasRDF ctdasrdf_invest_mappings.TTL ctdasrdf_invest.csv

@echo Importing SUPPDM 
call stardog-admin virtual import CTDasRDF SUPPDM_mappings.TTL SUPPDM_subset.csv

@echo Importing EX
call stardog-admin virtual import CTDasRDF EX_mappings.TTL EX_subset.csv


REM @echo Importing VS 
REM call stardog-admin virtual import CTDasRDF VS_mappings.TTL VS_subset.csv

@pause