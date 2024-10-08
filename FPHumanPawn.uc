//=============================================================================
// FMXHumanPawn
//=============================================================================
class FPHumanPawn extends SRHumanPawn;

// added to get around the const values normally set by native code and used by uscript animation code
var bool bFootTurning; 
var bool bFootStill;
var int  iFootRot;
var int  iTurnDir;
var int	 PawnTwist, PawnLook;
var float CrouchEyeHeightFactor;

simulated function Tick(float DeltaTime)
{
	super.Tick(DeltaTime);
	
	if( IsLocallyControlled() )
	{
		if( IsFirstPerson() )
		{
			if( bPhysicsAnimUpdate )
				bPhysicsAnimUpdate = false;
			UpdateMovementAnimation(DeltaTime);
		}
		else
		{
			if( !bPhysicsAnimUpdate )
				bPhysicsAnimUpdate = true;
		}
	}
	else
	{
		if( !bPhysicsAnimUpdate )
			bPhysicsAnimUpdate = true;
	}
}

simulated function UpdateMovementAnimation(FLOAT DeltaSeconds)
{
    if (Level.NetMode == NM_DedicatedServer)
        return;
    
    if (bPlayedDeath)
        return;
        
    if (Adjuster != none && Level.TimeSeconds - Adjuster.LastRenderTime > 1.0)
    {
        iFootRot = Rotation.Yaw;
        bFootTurning = false;
        bFootStill = false;
        return;
    }
 
    // Обновление высоты глаз в зависимости от состояния (приседание или нет)
    if (bIsCrouched)
    {
        BaseEyeHeight = Default.BaseEyeHeight * CrouchEyeHeightFactor; // Предполагается, что CrouchEyeHeightFactor - это коэффициент, который вы должны определить
    }
    else
    {
        BaseEyeHeight = Default.BaseEyeHeight;
    }
 
    if (!bWaitForAnim)
    {
        if (Physics == PHYS_Swimming)
        {
            BaseEyeHeight *= 0.7f;
            UpdateSwimming();
        }
        else if (Physics == PHYS_Falling || Physics == PHYS_Flying)
        {
            BaseEyeHeight *= 0.7f;
            UpdateInAir();
        }
        else if (Physics == PHYS_Walking || Physics == PHYS_Ladder)
        {
            UpdateOnGround();
        }
    }
    else if (!IsAnimating(0))
        bWaitForAnim = false;
 
    if (Physics != PHYS_Walking)
        bIsIdle = false;
 
    OldPhysics = Physics;
 
    if (bDoTorsoTwist)
        UpdateTwistLook(DeltaSeconds);
}
 
simulated function UpdateSwimming()
{
    if ( (Velocity.X*Velocity.X + Velocity.Y*Velocity.Y) < 2500.0f )
        PlayAnim(IdleSwimAnim, 1.0f, 0.1f, 0);
    else
	    PlayAnim(SwimAnims[Get4WayDirection()], 1.0f, 0.1f, 0);
}
 
simulated function UpdateInAir()
{
   local Name NewAnim;
   local  bool bUp, bDodge;
   local  float DodgeSpeedThresh;
   local int Dir;
   local  float XYVelocitySquared;
 
    XYVelocitySquared = (Velocity.X*Velocity.X)+(Velocity.Y*Velocity.Y);
 
    bDodge = false;
    if ( OldPhysics == PHYS_Walking )
    {
        DodgeSpeedThresh = ((GroundSpeed*DodgeSpeedFactor) + GroundSpeed) * 0.5f;
        if ( XYVelocitySquared > DodgeSpeedThresh*DodgeSpeedThresh )
        {
            bDodge = true;
        }
    }
 
    bUp = (Velocity.Z >= 0.0f);
 
    if (XYVelocitySquared >= 20000.0f)
    {
        Dir = Get4WayDirection();
 
        if (bDodge)
        {
            NewAnim = DodgeAnims[Dir];
            bWaitForAnim = true;
        }
        else if (bUp)
        {
            NewAnim = TakeoffAnims[Dir];
        }
        else
        {
            NewAnim = AirAnims[Dir];
        }
    }
    else
    {
        if (bUp)
        {
            NewAnim = TakeoffStillAnim;
        }
        else
        {
            NewAnim = AirStillAnim;
        }
    }
 
	if ( NewAnim != GetAnimSequence() )
    {	
		if ( PhysicsVolume.Gravity.Z > 0.8f * ( Class'PhysicsVolume'.Default.Gravity.Z ) )
			PlayAnim(NewAnim, 0.5f, 0.2f, 0);
		else
			PlayAnim(NewAnim, 1.0f, 0.1f, 0);
	}
}
 
simulated function UpdateOnGround()
{
    // just landed
    if ( OldPhysics == PHYS_Falling || OldPhysics == PHYS_Flying )
    {
        PlayLand();
    }
    // standing still
    else if ( Vsize(Velocity*Velocity) < 2500.0f  )  /*&& Acceleration.SizeSquared() < 0.01f*/
    {
        if (!bIsIdle || bFootTurning || bIsCrouched != bWasCrouched)
        {
            IdleTime = Level.TimeSeconds;
            PlayIdle();
        }
        PlayIdle();// added this playIdle to force the code to update whatever animation was playing, otherwise the turning anim could potentially continue to loop
        bWasCrouched = bIsCrouched;
        bIsIdle = true;
    }
    // running
    else
    {
        if ( bIsIdle  )
            bWaitForAnim = false;
 
        PlayRunning();
        bIsIdle = false;
    }
}
 
simulated function PlayIdle()
{
    if (bFootTurning)
    {
        if (iTurnDir == 1)
        {
            if (bIsCrouched)
                LoopAnim(CrouchTurnRightAnim, 1.0f, 0.1f, 0);
            else
    		    LoopAnim(TurnRightAnim, 1.0f, 0.1f, 0);
        }
        else
        {
            if (bIsCrouched)
    		    LoopAnim(CrouchTurnLeftAnim, 1.0f, 0.1f, 0);
            else
        	    LoopAnim(TurnLeftAnim, 1.0f, 0.1f, 0);
        }
    }
    else
    {
        if (bIsCrouched)
        {
            LoopAnim(IdleCrouchAnim, 1.0f, 0.1f, 0);
        }
        else
        {
			if (PlayerController(controller)!=none &&  PlayerController(controller).bIsTyping )
					PlayAnim(IdleRestAnim, 1.0f, 0.2f, 0);
			else if ( (Level.TimeSeconds - IdleTime < 5.0f) && IdleWeaponAnim != '')
			{
				LoopAnim(IdleWeaponAnim, 1.0f, 0.25f, 0);
			}
			else
			{
				LoopAnim(IdleRestAnim, 1.0f, 0.25f, 0);
			}
        }
    }
}
 
simulated function PlayRunning()
{
    local Name NewAnim;
    local int NewAnimDir;
    local float AnimSpeed;
 
    NewAnimDir = Get4WayDirection();
 
    AnimSpeed = 1.1f * Default.GroundSpeed;
    if (bIsCrouched)
    {
        NewAnim = CrouchAnims[NewAnimDir];
        AnimSpeed *= CrouchedPct;
    }
    else if (bIsWalking)
    {
        NewAnim = WalkAnims[NewAnimDir];
        AnimSpeed *= WalkingPct;
    }
    else
    {
        NewAnim = MovementAnims[NewAnimDir];
    }
    LoopAnim(NewAnim, (Vsize(Velocity)) / AnimSpeed, 0.1f, 0);
    //PlayAnim(0, NewAnim, Velocity.Size() / AnimSpeed, 0.1f, true); // native anim call
}
 
simulated function PlayLand()
{
    if (!bIsCrouched)
    {
        PlayAnim(LandAnims[Get4WayDirection()], 1.0f, 0.1f, 0);
        bWaitForAnim = true;
    }
}
 
simulated function UpdateTwistLook( float DeltaTime )
{
    local int Update, UpdateB, PitchDiff, YawDiff;
 
	if ( !bDoTorsoTwist || (Adjuster != none && Level.TimeSeconds - Adjuster.LastRenderTime > 0.5f) )
	{
		SmoothViewPitch = ViewPitch;
		SmoothViewYaw = Rotation.Yaw;
		iFootRot = Rotation.Yaw;
		bFootTurning = false;
		bFootStill = false;
	}
    else
    {
 		YawDiff = (Rotation.Yaw - SmoothViewYaw) & 65535;
		if ( YawDiff != 0 )
		{
			if ( YawDiff > 32768 )
				YawDiff -= 65536;
 
			Update = int(YawDiff * 15.f * DeltaTime);
			if ( Update == 0 ){
				//Update = (YawDiff > 0) ? 1 : -1;
				if (YawDiff>0) Update=1;
				else Update= -1;
			}
			SmoothViewYaw = (SmoothViewYaw + Update) & 65535;
		}
		PawnTwist = (SmoothViewYaw - iFootRot) & 65535;
        if (PawnTwist > 32768)
			PawnTwist -= 65536;
 
        if (((Velocity.X * Velocity.X) + (Velocity.Y * Velocity.Y)) < 1000 && Physics == PHYS_Walking)
        {
            if (!bFootStill)
            {
                bFootStill = true;
				SmoothViewYaw = Rotation.Yaw;
                iFootRot = Rotation.Yaw;
				PawnTwist = 0;
            }
        }
        else
        {
            if (bFootStill)
            {
                bFootStill = false;
                bFootTurning = true;
            }
        }
 
        if (bFootTurning)
        {
           if (PawnTwist > 12000)
            {
                iFootRot = SmoothViewYaw - 12000;
                PawnTwist = 12000;
            }
            else if (PawnTwist > 2048)
            {
                iFootRot += 16384*DeltaTime;
            }
            else if (PawnTwist < -12000)
            {
                iFootRot = SmoothViewYaw + 12000;
                PawnTwist = -12000;
            }
            else if (PawnTwist < -2048)
            {
                iFootRot -= 16384*DeltaTime;
            }
            else
            {
                if (!bFootStill)
                    PawnTwist = 0;
                bFootTurning = false;
            }
            iFootRot = iFootRot & 65535;
        }
        else if (bFootStill)
        {
            if (PawnTwist > 10923)
            {
                iTurnDir = 1;
                bFootTurning = true;
            }
            else if (PawnTwist < -10923)
            {
                iTurnDir = -1;
                bFootTurning = true;
            }
        }
        else
        {
            PawnTwist = 0;
        }
		PitchDiff = (256*ViewPitch - SmoothViewPitch) & 65535;
		if ( PitchDiff != 0 )
		{
			if ( PitchDiff > 32768 )
				PitchDiff -= 65536;
 
			UpdateB = int(PitchDiff * 5.f * DeltaTime);
			if ( UpdateB == 0 ){
				//Update = (PitchDiff > 0) ? 1 : -1;
				if (PitchDiff>0) UpdateB=1;
				else UpdateB= -1;
			}
			SmoothViewPitch = (SmoothViewPitch + UpdateB) & 65535;
		}
		PawnLook = SmoothViewPitch;
        if (PawnLook > 32768)
			PawnLook -= 65536;
        SetTwistLook(PawnTwist, PawnLook);
    }
}

simulated function Setup(xUtil.PlayerRecord rec, optional bool bLoadNow)
{
	Super.Setup(Rec, bLoadNow);
		
	bHasFootAdjust = False;
	FeetAdjSpec = Class<SPECIES_KFMaleHuman>(rec.Species);
	
	if( Adjuster!=None )
		Adjuster.Destroy();
	
	if( Controller != none && FeetAdjSpec != none && Level.NetMode != NM_DedicatedServer && Bot(Controller) == none && IsLocallyControlled() )
		SetupFirstPersonLegs(rec);
}

simulated function SetupFirstPersonLegs(xUtil.PlayerRecord Record)
{
	Adjuster = Controller.Spawn(class'FPActor', self,, Location, Rotation);
	Adjuster.AdjustingPawn = Self;
	Adjuster.SpecType = FeetAdjSpec;
	FPActor(Adjuster).InitAdjuster(Record.BodySkinName, Record.FaceSkinName);
}

defaultproperties
{
     bPhysicsAnimUpdate=False
	 CrouchEyeHeightFactor=0.5
}
