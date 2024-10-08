class FPPlayerController extends KFPCServ;

function ClientSetBehindView(bool B)
{
    local KFPawnFootAdjuster Adjuster;
    local FPActor FPLegs;
    
    super.ClientSetBehindView(B);
	
	if( Pawn != none )
	{	
		Adjuster = KFPawn(Pawn).Adjuster;
		
		if( Adjuster != none )
			FPLegs = FPActor(Adjuster);
		
		if(KFHumanPawn(Pawn) != none)
		{
			if( FPLegs != none )
			{
				FPLegs.bBehindViewToggled = B;
				FPLegs.AdjustBones(B);
			}
		}
	}
}

defaultproperties
{
     PawnClass=Class'ServerPerksDZ.FPHumanPawn'
}
