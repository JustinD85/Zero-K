unitDef = {
  unitname              = [[wolverine_mine]],
  name                  = [[Mine]],
  description           = [[Wolverine Mine]],
  acceleration          = 0,
  activateWhenBuilt     = false,
  bmcode                = [[0]],
  brakeRate             = 0,
  buildCostEnergy       = 20,
  buildCostMetal        = 20,
  builder               = false,
  buildPic              = [[CORMINE1.png]],
  buildTime             = 20,
  canAttack             = true,
  canGuard              = false,
  canMove               = false,
  canPatrol             = false,
  canstop               = [[0]],
  category              = [[FLOAT]],
  cloakCost             = 0,

  customParams          = {
    dontCount = [[1]],
  },

  defaultmissiontype    = [[Standby_Mine]],
  explodeAs             = [[NOWEAPON]],
  footprintX            = 1,
  footprintZ            = 1,
  iconType              = [[mine]],
  idleAutoHeal          = 10,
  idleTime              = 300,
  initCloaked           = true,
  mass                  = 39,
  maxDamage             = 40,
  maxSlope              = 255,
  maxVelocity           = 0,
  minCloakDistance      = 50,
  noAutoFire            = false,
  noChaseCategory       = [[FIXEDWING LAND SINK SHIP SATELLITE SWIM GUNSHIP FLOAT SUB HOVER]],
  objectName            = [[logmine.s3o]],
  onoffable             = false,
  seismicDistance       = 80,
  seismicSignature      = 16,
  selfDestructAs        = [[NOWEAPON]],
  selfDestructCountdown = 0,
  side                  = [[CORE]],
  sightDistance         = 64,
  smoothAnim            = true,
  stealth               = true,
  TEDClass              = [[SPECIAL]],
  turnRate              = 0,
  waterline             = 1,
  workerTime            = 0,
  yardMap               = [[y]],

  weapons               = {

    {
      def                = [[BOMBLET]],
      badTargetCategory  = [[GUNSHIP FIXEDWING]],
      onlyTargetCategory = [[LAND SINK SHIP SWIM FLOAT HOVER GUNSHIP FIXEDWING]],
    },

  },


  weaponDefs            = {

    BOMBLET = {
      name                    = [[Bomblet]],
      areaOfEffect            = 16,
      burst                   = 5,
      burstrate               = 0.01,
      craterBoost             = 0,
      craterMult              = 0,

      damage                  = {
        default = 40,
        planes  = 40,
        subs    = 4,
      },

      explosionGenerator      = [[custom:DEFAULT]],
      fireStarter             = 70,
      fixedlauncher           = 1,
      flightTime              = 1,
      guidance                = false,
      impactOnly              = true,
      impulseBoost            = 0.75,
      impulseFactor           = 0.3,
      interceptedByShieldType = 2,
      lineOfSight             = true,
      model                   = [[wep_b_fabby.s3o]],
      noSelfDamage            = true,
      range                   = 100,
      reloadtime              = 20,
      renderType              = 1,
      selfprop                = true,
      smokedelay              = [[.1]],
      smokeTrail              = true,
      soundHit                = [[explosion/ex_med5]],
      soundHitVolume          = 8,
      soundStart              = [[weapon/missile/sabot_fire]],
      soundStartVolume        = 7,
      startsmoke              = [[1]],
      startVelocity           = 50,
      texture2                = [[darksmoketrail]],
      tracks                  = true,
      turnRate                = 36000,
      turret                  = true,
      weaponAcceleration      = 200,
      weaponTimer             = 1,
      weaponType              = [[MissileLauncher]],
      weaponVelocity          = 300,
    },

  },

}

return lowerkeys({ wolverine_mine = unitDef })
