unitDef = {
  unitname            = [[commrecon1]],
  name                = [[Recon Commander]],
  description         = [[High Mobility Commander, Builds at 10 m/s]],
  acceleration        = 0.25,
  activateWhenBuilt   = true,
  amphibious          = [[1]],
  autoHeal            = 5,
  brakeRate           = 0.45,
  buildCostEnergy     = 1200,
  buildCostMetal      = 1200,
  buildDistance       = 120,
  builder             = true,

  buildoptions        = {
  },

  buildPic            = [[commrecon.png]],
  buildTime           = 1200,
  canAttack           = true,
  canGuard            = true,
  canMove             = true,
  canPatrol           = true,
  canreclamate        = [[1]],
  category            = [[LAND]],
  commander           = true,
  collisionVolumeOffsets = [[0 0 0]],
  collisionVolumeScales  = [[45 50 45]],
  collisionVolumeTest    = 1,
  collisionVolumeType    = [[CylY]],  
  corpse              = [[DEAD]],

  customParams        = {
    canjump   = [[1]],
	cloakstealth = [[1]],
	jumpclass = [[commrecon1]],
	description_de = [[Hochmobiler Kommandant, Baut mit 10 M/s]],
	description_pl = [[Mobilny Dowodca, moc 10 m/s]],
	helptext       = [[The Recon Commander revolves around mobility and guile; this lightly armored platform can mount many special weapons and modules and comes pre-equipped with jumpjets.]],
	helptext_de    = [[Bei dem Recon Commander dreht sich alles um Mobilit�t und List. Dieser schwach gepanzerte Grundsatz kann um viele Spezialwaffen und -module erweitert werden. Er besitzt au�erdem einen D?enstrahl zum Springen.]],
	helptext_pl    = [[Recon to Dowodca oparty na na szybkosci i przebieglosci; moze uzywac wielu egzotycznych broni i jest wyposazony w mozliwosc skoku.]],
	level = [[1]],
	statsname = [[commrecon1]],
	soundok = [[heavy_bot_move]],
	soundselect = [[bot_select]],
	soundbuild = [[builder_start]],
    commtype = [[3]],
  },

  energyMake          = 8,
  energyStorage       = 0,
  energyUse           = 0,
  explodeAs           = [[ESTOR_BUILDINGEX]],
  footprintX          = 2,
  footprintZ          = 2,
  hideDamage          = false,
  iconType            = [[commander1]],
  idleAutoHeal        = 5,
  idleTime            = 1800,
  leaveTracks         = true,
  mass                = 407,
  maxDamage           = 1800,
  maxSlope            = 36,
  maxVelocity         = 1.45,
  maxWaterDepth       = 5000,
  metalMake           = 4,
  metalStorage        = 0,
  minCloakDistance    = 75,
  movementClass       = [[AKBOT2]],
  noChaseCategory     = [[TERRAFORM SATELLITE FIXEDWING GUNSHIP HOVER SHIP SWIM SUB LAND FLOAT SINK TURRET]],
  norestrict          = [[1]],
  objectName          = [[commrecon.s3o]],
  script              = [[commrecon.lua]],
  seismicSignature    = 16,
  selfDestructAs      = [[ESTOR_BUILDINGEX]],

  sfxtypes            = {

    explosiongenerators = {
	  [[custom:NONE]],
	  [[custom:NONE]],
      [[custom:RAIDMUZZLE]],
	  [[custom:NONE]],
      [[custom:VINDIBACK]],
      [[custom:FLASH64]],
    },

  },

  showNanoSpray       = false,
  showPlayerName      = true,
  side                = [[ARM]],
  sightDistance       = 500,
  smoothAnim          = true,
  sonarDistance       = 300,
  trackOffset         = 0,
  trackStrength       = 8,
  trackStretch        = 1,
  trackType           = [[ComTrack]],
  trackWidth          = 22,
  terraformSpeed      = 600,
  turnRate            = 1350,
  upright             = true,
  workerTime          = 10,

  weapons             = {
  
	[1] = {
      def                = [[FAKELASER]],
      badTargetCategory  = [[FIXEDWING]],
      onlyTargetCategory = [[FIXEDWING LAND SINK TURRET SHIP SWIM FLOAT GUNSHIP HOVER]],	
	},
  
    [5] = {
      def                = [[SLOWBEAM]],
      badTargetCategory  = [[FIXEDWING]],
      onlyTargetCategory = [[FIXEDWING LAND SINK TURRET SHIP SWIM FLOAT GUNSHIP HOVER]],
    },

  },


  weaponDefs          = {

    FAKELASER     = {
      name                    = [[Fake Laser]],
      areaOfEffect            = 12,
      beamlaser               = 1,
      beamTime                = 0.1,
      coreThickness           = 0.5,
      craterBoost             = 0,
      craterMult              = 0,

      damage                  = {
        default = 0,
      },

      duration                = 0.11,
      explosionGenerator      = [[custom:flash1green]],
      impactOnly              = true,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 1,
      laserFlareSize          = 5.53,
      lineOfSight             = true,
      minIntensity            = 1,
      range                   = 400,
      reloadtime              = 0.11,
      renderType              = 0,
      rgbColor                = [[0 1 0]],
      sweepfire               = false,
      texture1                = [[largelaser]],
      texture2                = [[flare]],
      texture3                = [[flare]],
      texture4                = [[smallflare]],
      thickness               = 5.53,
      tolerance               = 10000,
      turret                  = true,
      weaponType              = [[BeamLaser]],
      weaponVelocity          = 900,
    },
  
    SLOWBEAM = {
      name                    = [[Slowing Beam]],
      areaOfEffect            = 8,
      beamDecay               = 0.9,
      beamlaser               = 1,
      beamTime                = 0.1,
      beamttl                 = 50,
      coreThickness           = 0,
      craterBoost             = 0,
      craterMult              = 0,

      customParams            = {
        timeslow_preset = [[commrecon_slowbeam]],
      },

      damage                  = {
        default = 225,
      },

      explosionGenerator      = [[custom:flashslow]],
      fireStarter             = 30,
      impactOnly              = true,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 1,
      largeBeamLaser          = true,
      laserFlareSize          = 6,
      lineOfSight             = true,
      minIntensity            = 1,
      noSelfDamage            = true,
      range                   = 400,
      reloadtime              = 1.5,
      renderType              = 0,
      rgbColor                = [[0.4 0 0.5]],
      soundStart              = [[weapon/laser/pulse_laser2]],
      soundStartVolume        = 0.9,
      soundTrigger            = true,
      sweepfire               = false,
      texture1                = [[largelaser]],
      texture2                = [[flare]],
      texture3                = [[flare]],
      texture4                = [[smallflare]],
      thickness               = 8,
      tolerance               = 18000,
      turret                  = true,
      weaponType              = [[BeamLaser]],
      weaponVelocity          = 500,
    },

  },


  featureDefs         = {

    DEAD      = {
      description      = [[Wreckage - Recon Commander]],
      blocking         = true,
      category         = [[corpses]],
      damage           = 1800,
      energy           = 0,
      featureDead      = [[HEAP]],
      featurereclamate = [[SMUDGE01]],
      footprintX       = 2,
      footprintZ       = 2,
      height           = [[20]],
      hitdensity       = [[100]],
      metal            = 480,
      object           = [[commrecon_dead.s3o]],
      reclaimable      = true,
      reclaimTime      = 480,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },


    HEAP      = {
      description      = [[Debris - Recon Commander]],
      blocking         = false,
      category         = [[heaps]],
      damage           = 1800,
      energy           = 0,
      featurereclamate = [[SMUDGE01]],
      footprintX       = 2,
      footprintZ       = 2,
      hitdensity       = [[100]],
      metal            = 480,
      object           = [[debris2x2c.s3o]],
      reclaimable      = true,
      reclaimTime      = 480,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },

  },

}

return lowerkeys({ commrecon1 = unitDef })
