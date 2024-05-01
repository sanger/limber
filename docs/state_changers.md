<!--
# @markup markdown
# @title Available State Changers
-->

# Available State Changers

> **Note** This file is generated automatically by `rake docs:update` and should
> be generated automatically if you run `rake config:generate` in development.
> If you wish to modify the file, update `docs/templates/state_changers.md.erb`
> instead. The description of each class is pulled directly from the class itself.

State changers are responsible for updating labware state either via robot or
manual transfer.


## StateChangers::DefaultStateChanger

{include:StateChangers::DefaultStateChanger}

  Used directly in 187 purposes:
  CLCM DNA End Prep, CLCM DNA Lib PCR, CLCM DNA Lib PCR XP, CLCM Lysate DNA, CLCM Lysate RNA, CLCM RNA End Prep, CLCM RNA Lib PCR, CLCM RNA Lib PCR XP, CLCM RT PreAmp, CLCM Stock, GBS PCR1, GBS PCR2, GBS Stock, GBS-96 Stock, GnT MDA Norm, GnT Pico End Prep, GnT Pico Lib PCR, GnT Pico-XP, GnT scDNA, GnT Stock, Heron Lysed Tube Rack, LB Cap Lib, LB Cap Lib PCR, LB Cap Lib PCR-XP, LB Cap Lib Pool, LB cDNA, LB cDNA XP, LB Cherrypick, LB End Prep, LB Hyb, LB Lib PCR, LB Lib PCR-XP, LB Lib PrePool, LB Post Shear, LB Shear, LBB Cherrypick, LBB Chromium Tagged, LBB Enriched BCR, LBB Enriched BCR HT, LBB Enriched TCR, LBB Enriched TCR HT, LBB Lib PCR-XP, LBB Lib-XP, LBB Ligation, LBB Ligation Tagged, LBC 3pV3 GEX Dil, LBC 3pV3 GEX Frag 2XP, LBC 3pV3 GEX LigXP, LBC 3pV3 GEX PCR 2XP, LBC 5p GEX Dil, LBC 5p GEX Frag 2XP, LBC 5p GEX LigXP, LBC 5p GEX PCR 2XP, LBC Aggregate, LBC BCR Dil 1, LBC BCR Dil 2, LBC BCR Enrich1 2XSPRI, LBC BCR Enrich2 2XSPRI, LBC BCR Post Lig 1XSPRI, LBC BCR Post PCR, LBC Stock, LBC TCR Dil 1, LBC TCR Dil 2, LBC TCR Enrich1 2XSPRI, LBC TCR Enrich2 2XSPRI, LBC TCR Post Lig 1XSPRI, LBC TCR Post PCR, LBR Cherrypick, LBR Frag, LBR Frag cDNA, LBR Globin, LBR Globin DNase, LBR mRNA Cap, LBR Ribo DNase, LBR RiboGlobin DNase, LBSN-384 PCR 1, LBSN-384 PCR 2, LCA 10X cDNA, LCA Blood Array, LCA Blood Bank, LCA Connect PCRXP, LCA PBMC, LCA PBMC Bank, LCA PBMC Pools, LCMB Cherrypick, LCMB End Prep, LCMB Lib PCR, LCMB Lib PCR-XP, LDS AL Lib, LDS AL Lib Dil, LDS Cherrypick, LDS Lib PCR, LDS Lib PCR XP, LDS Stock, LDS Stock XP, LDW-96 Stock, LHR End Prep, LHR Lib PCR, LHR PCR 1, LHR PCR 2, LHR RT, LHR XP, LHR-384 AL Lib, LHR-384 cDNA, LHR-384 End Prep, LHR-384 Lib PCR, LHR-384 PCR 1, LHR-384 PCR 2, LHR-384 RT, LHR-384 XP, LILYS-96 Stock, LRC Blood Bank, LRC HT 5p Aggregate, LRC HT 5p cDNA Input, LRC HT 5p cDNA PCR, LRC HT 5p Chip, LRC HT 5p GEMs, LRC HT 5p GEX Dil, LRC PBMC Bank, LRC PBMC Cryostor, LRC PBMC Defrost PBS, LRC PBMC Pools, LRC PBMC Pools Input, LTHR Cherrypick, LTHR Lib PCR 1, LTHR Lib PCR 2, LTHR Lib PCR pool, LTHR PCR 1, LTHR PCR 2, LTHR RT, LTHR RT-S, LTHR-384 Lib PCR 1, LTHR-384 Lib PCR 2, LTHR-384 Lib PCR pool, LTHR-384 PCR 1, LTHR-384 PCR 2, LTHR-384 RT, LTHR-384 RT-Q, LTN AL Lib, LTN AL Lib Dil, LTN Cherrypick, LTN Lib PCR, LTN Lib PCR XP, LTN Post Shear, LTN Shear, LTN Stock, LTN Stock XP, PF Cherrypicked, PF End Prep, PF Lib, PF Lib Q-XP2, PF Lib XP, PF Lib XP2, PF Post Shear, PF Post Shear XP, PF Shear, PF-384 End Prep, PF-384 Lib, PF-384 Lib XP2, PF-384 Post Shear XP, pWGS-384 AL Lib, pWGS-384 End Prep, pWGS-384 Lib PCR, pWGS-384 Post Shear XP, RVI Cap Lib, RVI Cap Lib PCR, RVI Cap Lib PCR XP, RVI Cap Lib Pool, RVI cDNA XP, RVI Cherrypick, RVI Hyb, RVI Lib PCR, RVI Lib PCR XP, RVI Lib PrePool, RVI Lig Bind, RVI RT, scRNA cDNA-XP, scRNA End Prep, scRNA Lib PCR, scRNA Stock, scRNA-384 cDNA-XP, scRNA-384 End Prep, scRNA-384 Lib PCR, scRNA-384 Stock, Tag Plate - 384, TR Stock 48, and TR Stock 96

{StateChangers::DefaultStateChanger View class documentation}


## StateChangers::AutomaticTubeStateChanger

{include:StateChangers::AutomaticTubeStateChanger}

  Used directly in 2 purposes:
  LRC Bank Seq and LRC Bank Spare

{StateChangers::AutomaticTubeStateChanger View class documentation}


## StateChangers::AutomaticPlateStateChanger

{include:StateChangers::AutomaticPlateStateChanger}

  Used directly in 5 purposes:
  LBC Cherrypick, LBSN-96 Lysate, LRC HT 5p cDNA PCR XP, LRC HT 5p Cherrypick, and LSW-96 Stock

{StateChangers::AutomaticPlateStateChanger View class documentation}


## StateChangers::AutomaticLabwareStateChanger

{include:StateChangers::AutomaticLabwareStateChanger}

  **This state changer is unused**

{StateChangers::AutomaticLabwareStateChanger View class documentation}


## StateChangers::TubeStateChanger

{include:StateChangers::TubeStateChanger}

  Used directly in 47 purposes:
  Cap Lib Pool Norm, CLCM DNA Pool, CLCM DNA Pool Norm, CLCM RNA Pool, CLCM RNA Pool Norm, GBS MiSeq Pool, GBS PCR Pool, GBS PCR Pool Selected, GBS PCR2 Pool Stock, GnT Pico Lib Pool, GnT Pico Lib Pool XP, LB Custom Pool, LB Custom Pool Norm, LB Lib Pool, LB Lib Pool Norm, LBB Lib Pool Stock, LBC 3pV3 GLibPS, LBC 5p GLibPS, LBC 5p Pool Norm, LBC BCR LibPS, LBC BCR Pool Norm, LBC TCR LibPS, LBC TCR Pool Norm, LBSN-384 PCR 2 Pool, LBSN-9216 Lib PCR Pool, LBSN-9216 Lib PCR Pool XP, LCA Bank Stock, LCA Blood Vac, LCA Custom Pool, LCA Custom Pool Norm, LCMB Custom Pool, LCMB Custom Pool Norm, LDS Custom Pool, LDS Custom Pool Norm, LHR Lib Pool, LHR Lib Pool XP, LHR-384 Pool XP, LRC Blood Aliquot, LRC Blood Vac, LTHR Pool XP, LTHR-384 Pool XP, LTN Custom Pool, LTN Custom Pool Norm, pWGS-384 Lib Pool XP, scRNA Lib Pool, scRNA Lib Pool XP, and scRNA-384 Lib Pool XP

{StateChangers::TubeStateChanger View class documentation}

