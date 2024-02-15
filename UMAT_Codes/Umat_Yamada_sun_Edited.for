
      SUBROUTINE UMAT(STRESS,STATEV,DDSDDE,SSE,SPD,SCD,
     1 RPL,DDSDDT,DRPLDE,DRPLDT,
     2 STRAN,DSTRAN,TIME,DTIME,TEMP,DTEMP,PREDEF,DPRED,CMNAME,
     3 NDI,NSHR,NTENS,NSTATEV,PROPS,NPROPS,COORDS,DROT,PNEWDT,
     4 CELENT,DFGRD0,DFGRD1,NOEL,NPT,LAYER,KSPT,KSTEP,KINC)

      INCLUDE 'ABA_PARAM.INC'

      CHARACTER*80 CMNAME
      DIMENSION STRESS(NTENS),STATEV(NSTATEV),
     1 DDSDDE(NTENS,NTENS),DDSDDT(NTENS),DRPLDE(NTENS),
     2 STRAN(NTENS),DSTRAN(NTENS),TIME(2),PREDEF(1),DPRED(1),
     3 PROPS(NPROPS),COORDS(3),DROT(3,3),DFGRD0(3,3),DFGRD1(3,3)
     
      INTEGER i,j
      DOUBLE PRECISION Dgrd(6),DMG(9),FI(5),STRANT(NTENS)
!C Data
!C=========================================================================		  
!C Read ELASTIC PROPERTIES
      E11  = PROPS(1)
      E22  = PROPS(2)
      E33  = PROPS(3)
      NU12 = PROPS(4)
      NU13 = PROPS(5)
      NU23 = PROPS(6)   
      G12  = PROPS(7)
      G13  = PROPS(8)
      G23  = PROPS(9) 
!C Calculate Some PROPERTIES
      NU21 = (E22 * NU12) / E11
      NU31 = (E33 * NU13) / E11
      NU32 = (E33 * NU23) / E22
!C Read Failure Stresses (Tension,Compression,Shear)
      Xt   = PROPS(10)
      Xc   = PROPS(11)
      Yt   = PROPS(12)
      Yc   = PROPS(13)
      Zt   = PROPS(14)
      Zc   = PROPS(15)
      S12  = PROPS(16)
      S13  = PROPS(17)
      S23  = PROPS(18)
	  Sc   = PROPS(19)
!C Read Degredation Parameters (DT1/DC1/DT2/DC2/DT4/DC4)
      Dgrd(1:6)  = PROPS(20:25)
!C Read Degredation Method (1 = Complete / 2 = Camanho's) 
      DEG  = PROPS(26)  
      IF (STATEV(15).EQ.0) THEN
        STATEV(1:9) = 1.0D0
        STATEV(15)  = 1.0D0
      ENDIF

!C Degredation Value
      DMG(1:9)  = STATEV(1:9)
!C=========================================================================		  
!C Calculation
      ! Strain
      DO j=1,NTENS
        STRANT = STRAN + DSTRAN
      ENDDO
      ! DDSDDE
      Call Constitutive(DDSDDE,E11,E22,E33,G12,G13,G23,NU12,NU13,
     1 NU23,NU21,NU31,NU32,NTENS,DEG,DMG)
      ! Stress
      DO i=1,NTENS
      	STRESS(i)=0.0D0
      	DO j=1,NTENS
      		STRESS(i)=STRESS(i)+DDSDDE(j,i)*STRANT(j)
      	ENDDO
      ENDDO
      ! Failure Index
      FI(1:5) = 0.0D0
      CALL FailureIndex(STRESS,Xt,Xc,Yt,Yc,Zt,Zc,Sc,S12,S13,S23,FI
     1 ,NTENS)
      ! Check Failure Index
      ! 1 Fiber Tension Index
      IF (FI(1).GT.1.0) THEN
      	DMG(7) = 0.0D0
      	DMG(1) = DMG(1) * Dgrd(1)
        DMG(4) = DMG(4) * Dgrd(4)
        DMG(6) = DMG(6) * Dgrd(6)
      ENDIF
      ! 2 Fiber Compression Index
      IF (FI(2).GT.1.0) THEN
      	DMG(7) = 0.0D0
      	DMG(2) = DMG(2) * Dgrd(2)
      ENDIF
      ! 3 Matrix Tension Index
      IF (FI(3).GT.1.0) THEN
      	DMG(8) = 0.0D0
      	DMG(3) = DMG(3) * Dgrd(3)
        DMG(5) = DMG(5) * Dgrd(5)
      ENDIF
      ! 4 Matrix Compression Index
      IF (FI(4).GT.1.0) THEN
      	DMG(8) = 0.0D0
      	DMG(4) = DMG(4) * Dgrd(4)
        DMG(6) = DMG(6) * Dgrd(6)
      ENDIF
	  ! 5 Fiber-Matrix Shear
      IF (FI(5).GT.1.0) THEN
      	DMG(9) = 0.0D0
      	DMG(4) = DMG(4) * Dgrd(4)
        DMG(6) = DMG(6) * Dgrd(6)
      ENDIF
	  
      ! Update STATEV
      STATEV(1:9)  = abs(DMG(1:9))
      STATEV(10:14) = FI(1:5)
      RETURN                          
      END 
	  
!C=========================================================================	
!C Define SUBROUTINE To Calculate Constitutive Matrix
!C=========================================================================	
      SUBROUTINE Constitutive(DDSDDE,E11,E22,E33,G12,G13,G23,NU12,NU13,
     1 NU23,NU21,NU31,NU32,NTENS,DEG,DMG)
      INCLUDE 'ABA_PARAM.INC'
      DOUBLE PRECISION DDSDDE(NTENS,NTENS),E11,E22,E33,G12,G13,G23,NU12,
     1 NU13,NU23,NU21,NU31,NU32,DEG,DMG(9)
      INTEGER NTENS
      IF(DEG.EQ.1) THEN
     	E11  = E11  * abs(DMG(7))
     	E22  = E22  * abs(DMG(7) * DMG(8)) 
     	E33  = E33  * abs(DMG(7) * DMG(8))
     	NU12 = NU12 * abs(DMG(7) * DMG(8) * DMG(9))
     	NU13 = NU13 * abs(DMG(7))          
     	NU23 = NU23 * abs(DMG(7))          
     	G12  = G12  * abs(DMG(7) * DMG(9)) 
     	G13  = G13  * abs(DMG(7))          
     	G23  = G23  * abs(DMG(7))          
     	NU21 = NU21 * abs(DMG(7) * DMG(8) * DMG(9)) 
     	NU31 = NU31 * abs(DMG(7))          
     	NU32 = NU32 * abs(DMG(7))          
      ELSE
     	E11  = E11  * abs(DMG(1) * DMG(2))
     	E22  = E22  * abs(DMG(3) * DMG(4))
     	G12  = G12  * abs(DMG(5) * DMG(6))
     	G23  = G23  * abs(DMG(5) * DMG(6))
      END IF
	  
      DELTA = 1/(1-NU12*NU21-NU23*NU32-NU13*NU31-2*NU21*NU32*NU13)
      DDSDDE(1,1) = E11 * (1-NU23*NU32)    * DELTA
      DDSDDE(1,2) = E22 * (NU12+NU32*NU13) * DELTA
      DDSDDE(1,3) = E11 * (NU31+NU21*NU32) * DELTA
      DDSDDE(2,1) = DDSDDE(1,2)
      DDSDDE(2,2) = E22 * (1-NU13*NU31)    * DELTA
      DDSDDE(2,3) = E22 * (NU32+NU12*NU31) * DELTA
      DDSDDE(3,1) = DDSDDE(1,3)
      DDSDDE(3,2) = DDSDDE(2,3)
      DDSDDE(3,3) = E33 * (1-NU12*NU21)    * DELTA
      DDSDDE(4,4) = G12
      DDSDDE(5,5) = G13
      DDSDDE(6,6) = G23  	
	  
      RETURN
      END
!C=========================================================================	
!C Define SUBROUTINE To Calculate Failure Index
!C=========================================================================	
      SUBROUTINE FailureIndex(STRESS,Xt,Xc,Yt,Yc,Zt,Zc,Sc,S12,S13,S23,FI
     1 ,NTENS)
      INCLUDE 'ABA_PARAM.INC'
      INTEGER NTENS
      DOUBLE PRECISION STRESS(NTENS),Xt,Xc,Yt,Yc,Zt,Zc,Sc,S12,S13,S23,
     1 FI(5)
      IF (STRESS(1).GT.0) THEN
      ! Fiber Tension
      FI(1) = (STRESS(1)/Xt)**2
     1 + (STRESS(4)/Sc)**2
      ELSE
      	! Fiber Compression
      FI(2) = (STRESS(1)/Xc)**2
     1 + (STRESS(4)/Sc)**2
      END IF
      IF ((STRESS(2)+STRESS(3)).GT.0) THEN
      ! Matrix Tension
      FI(3) = (STRESS(2)/Yt)**2
     1 + (STRESS(4)/Sc)**2
      ELSE
      ! Matrix Compression
      FI(4) = (STRESS(2)/Sc)**2
     1 + ((Yc/(2*Sc))**2-1)
     2 * (STRESS(2)/Yc)
     3 + (STRESS(4)/Sc)**2 
      END IF
	  ! Fiber-Matrix Shear
      FI(5) = (STRESS(1)/Xt)**2
     1 + (STRESS(4)/Sc)**2
	  
      RETURN                          
      END                  