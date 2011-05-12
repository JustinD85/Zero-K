unitDef = {
  unitname               = [[armcomdgun]],
  name                   = [[Ultimatum]],
  description            = [[Disintegrator Walker (Anti-Strider)]],
  acceleration           = 0.18,
  activateWhenBuilt      = false,
  amphibious             = [[1]],
  autoHeal               = 5,
  brakeRate              = 0.375,
  buildCostEnergy        = 2000,
  buildCostMetal         = 2000,
  buildPic               = [[armcomdgun.png]],
  buildTime              = 2000,
  canAttack              = true,
  canDGun                = false,
  canGuard               = true,
  canMove                = true,
  canPatrol              = true,
  canreclamate           = [[1]],
  canstop                = [[1]],
  category               = [[LAND]],
  cloakCost              = 8,
  cloakCostMoving        = 24,
  collisionVolumeOffsets = [[0 0 0]],
  collisionVolumeScales  = [[35 35 35]],
  collisionVolumeTest    = 1,
  collisionVolumeType    = [[ellipsoid]],
  corpse                 = [[DEAD]],

  customParams           = {
	description_de = [[Desintegrator Wanderer (Anti-Strider)]],	
    helptext  = [[The Ultimatum packs only one weapon: a disintegrator gun that can vaporize a heavy tank in one blast. It is best used for sneaking up to enemy heavy striders and inflicting serious damage or destruction with a few shots. Defense against it is achieved by screening your heavyweights with lighter units.]],
	helptext_de    = [[Ultimatum beinhaltet nur eine Waffe: ein Desintegrator, welche gegnerische Panzer mit einem Schlag vaporisieren kann. Am meisten wird daf�r er gebraucht, sich an gegenerische, harte Streicher heranzuschleichen und diese mit einigen Sch�ssen zu erledigen. Verteidigung gegen sie wird erreicht, indem man seine Schwergewicht mit leichten Einheiten besch�tzt.]],
  },

  defaultmissiontype     = [[Standby]],
  energyUse              = 0,
  explodeAs              = [[ESTOR_BUILDING]],
  footprintX             = 2,
  footprintZ             = 2,
  iconType               = [[corcommander]],
  idleAutoHeal           = 5,
  idleTime               = 1800,
  leaveTracks            = true,
  mass                   = 444,
  maxDamage              = 2000,
  maxSlope               = 36,
  maxVelocity            = 1.45,
  maxWaterDepth          = 5000,
  minCloakDistance       = 100,
  movementClass          = [[AKBOT2]],
  noChaseCategory        = [[TERRAFORM SATELLITE FIXEDWING GUNSHIP HOVER SHIP SWIM SUB LAND FLOAT SINK]],
  objectName             = [[noruas]],
  script                 = [[noruas.cob]],
  seismicSignature       = 16,
  selfDestructAs         = [[ESTOR_BUILDING]],

  sfxtypes               = {

    explosiongenerators = {
      [[custom:GATE]],
    },

  },

  showNanoSpray          = false,
  side                   = [[ARM]],
  sightDistance          = 500,
  smoothAnim             = true,
  sonarDistance          = 300,
  trackOffset            = 0,
  trackStrength          = 8,
  trackStretch           = 1,
  trackType              = [[ComTrack]],
  trackWidth             = 14,
  turnRate               = 1148,
  upright                = true,

  weapons                = {

    {
      def = [[DISINTEGRATOR]],
    },

  },


  weaponDefs             = {

    DISINTEGRATOR = {
      name                    = [[Disintegrator]],
      areaOfEffect            = 48,
      avoidFeature            = false,
      avoidFriendly           = false,
      avoidNeutral            = false,
      commandfire             = false,
      craterBoost             = 1,
      craterMult              = 6,

      damage                  = {
        default = 1200,
      },

      explosionGenerator      = [[custom:DGUNTRACE]],
      impulseBoost            = 0,
      impulseFactor           = 0,
      interceptedByShieldType = 0,
      noExplode               = true,
      noSelfDamage            = true,
      range                   = 250,
      reloadtime              = 1.5,
      renderType              = 3,
	  size					  = 6,
      soundHit                = [[explosion/ex_med6]],
      soundStart              = [[weapon/laser/heavy_laser4]],
      soundTrigger            = true,
      tolerance               = 10000,
      turret                  = true,
      weaponTimer             = 4.2,
      weaponType              = [[DGun]],
      weaponVelocity          = 300,
    },

  },


  featureDefs            = {

    DEAD      = {
      description      = [[Wreckage - Ultimatum]],
      blocking         = true,
      category         = [[corpses]],
      damage           = 2000,
      energy           = 0,
      featureDead      = [[DEAD2]],
      featurereclamate = [[SMUDGE01]],
      footprintX       = 2,
      footprintZ       = 2,
      height           = [[20]],
      hitdensity       = [[100]],
      metal            = 800,
      object           = [[wreck3x3b.s3o]],
      reclaimable      = true,
      reclaimTime      = 800,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },


    DEAD2     = {
      description      = [[Debris - Ultimatum]],
      blocking         = false,
      category         = [[heaps]],
      damage           = 2000,
      energy           = 0,
      featureDead      = [[HEAP]],
      featurereclamate = [[SMUDGE01]],
      footprintX       = 2,
      footprintZ       = 2,
      hitdensity       = [[100]],
      metal            = 800,
      object           = [[debris2x2b.s3o]],
      reclaimable      = true,
      reclaimTime      = 800,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },


    HEAP      = {
      description      = [[Debris - Ultimatum]],
      blocking         = false,
      category         = [[heaps]],
      damage           = 2000,
      energy           = 0,
      featurereclamate = [[SMUDGE01]],
      footprintX       = 2,
      footprintZ       = 2,
      hitdensity       = [[100]],
      metal            = 400,
      object           = [[debris2x2b.s3o]],
      reclaimable      = true,
      reclaimTime      = 400,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },

  },

}

return lowerkeys({ armcomdgun = unitDef })
