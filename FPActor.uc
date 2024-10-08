class FPActor extends KFPawnFootAdjuster;

var int BodyLoc, CrouchLoc;
var Controller PawnController;
var bool bBehindViewToggled;
var float AlphaTime;

simulated function PostBeginPlay()
{
	Super.PostBeginPlay();
	SetTimer(0.5,true);
}

simulated function InitAdjuster(string BodySkin, string FaceSkin)
{
	if( AdjustingPawn == none || AdjustingPawn.Controller == none )
		Destroy();
		
	LinkMesh(AdjustingPawn.Mesh);
	
	Skins[0] = Material(DynamicLoadObject(BodySkin, class'Material', true));
	Skins[1] = Material(DynamicLoadObject(FaceSkin, class'Material', true));
	
	PawnController = AdjustingPawn.Controller;

	AdjustBones(false);
}

simulated function AdjustBones(bool B)
{
	if( AdjustingPawn == none || PawnController == none )
		Destroy();
		
	if( bHidden != B )
		bHidden = B;
	
	if( B )
	{	
		AdjustingPawn.SetBoneScale(1, 1.0, 'CHR_LArmUpper');
		AdjustingPawn.SetBoneScale(2, 1.0, 'CHR_RArmUpper');
		AdjustingPawn.SetBoneScale(4, 1.0, 'CHR_Head');
	}
	else
	{
		AdjustingPawn.SetBoneScale(1, 0.001, 'CHR_LArmUpper');
		AdjustingPawn.SetBoneScale(2, 0.001, 'CHR_RArmUpper');
		AdjustingPawn.SetBoneScale(4, 0.001, 'CHR_Head');	
	}
}

simulated function Tick(float DeltaTime)
{
	local Vector PawnRotation,DrawOffset,PawnLocation;
	local FPHumanPawn FHumanPawn;
	local vector V;

	Super.Tick(DeltaTime);

	if(PawnController == none || AdjustingPawn == none)
		Destroy();
	
	FHumanPawn = FPHumanPawn(AdjustingPawn);

	PawnRotation = vector(AdjustingPawn.Rotation);
	PawnRotation.Z = 0.00;
	DrawOffset = AdjustingPawn.EyePosition();
	DrawOffset.Z -= 42;

	if( AdjustingPawn != none )
	{
		if( AdjustingPawn.bIsCrouched )
		{
			PawnRotation = float(CrouchLoc) * Normal(PawnRotation);
			AlphaTime = FMin(AlphaTime+(DeltaTime*6.f),1.f);
		}
		else
		{
			PawnRotation = float(BodyLoc) * Normal(PawnRotation);
			AlphaTime = FMax(AlphaTime-(DeltaTime*4.f),0.f);
		}

		V = vect(1.35,0,33.5)*AlphaTime + vect(0.41,0,10.5)*(1.f-AlphaTime);
		PawnLocation = AdjustingPawn.Location + DrawOffset + (V >> AdjustingPawn.Rotation);
	
		SetLocation(PawnLocation + PawnRotation);
		SetRotation(AdjustingPawn.Rotation);
	}
	
	if(AdjustingPawn != none && AdjustingPawn.IsFirstPerson() && FHumanPawn != none)
		AdjustingPawn.SetTwistLook(FHumanPawn.PawnTwist, 0);
	else if( FHumanPawn != none && FHumanPawn.PawnTwist != 0 )
		FHumanPawn.PawnTwist = 0;
}

simulated function Timer()
{
	local bool BoneReset;
	
	Super.Timer();

	if( (PawnController.IsInState('PlayerFlying') || PawnController.Pawn.Physics == PHYS_Swimming) && !BoneReset )
	{
		BoneReset = true;
		AdjustBones(true);
	}
	else if( (PawnController.IsInState('PlayerWalking') || PawnController.Pawn.Physics == PHYS_Walking) && !bBehindViewToggled )
	{
		BoneReset = false;
		AdjustBones(false);
	}
}

Auto state Setup
{
Begin:
	AdjustingPawn.bHasFootAdjust = True;
	Stop;
}

defaultproperties
{
     BodyLoc=-21
     CrouchLoc=-23
     bHidden=False
     bOnlyOwnerSee=True
     RemoteRole=ROLE_SimulatedProxy
     bAnimByOwner=True
     bClientAnim=True
     bNoRepMesh=True
}
