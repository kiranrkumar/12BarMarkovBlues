; 12-bar blues based on Markov tables
; Kiran Kumar
; 12 Nov, 2015

<CsoundSynthesizer>
<CsOptions>
</CsOptions>
<CsInstruments>
sr = 44100
kr = 44100 
0dbfs = 1
nchnls = 2
seed 0

gkCounter init 0 ; to keep track of the blues progression

;****USER DEFINED OPCODES FOR MARKOV CHAINS****
opcode Markov, i, i[][]i
	iMarkovTable[][], iPrevEl xin
	iRandom    random     0, 1
	iNextEl    =          0
	iAccum     =          iMarkovTable[iPrevEl][iNextEl]
	until iAccum >= iRandom do
		iNextEl    +=         1
		iAccum     +=         iMarkovTable[iPrevEl][iNextEl]
	enduntil
     
     xout       iNextEl
endop

opcode Markovk, k, k[][]k
	kMarkovTable[][], kPrevEl xin
	kRandom    random     0, 1
	kNextEl    =          0
	kAccum     =          kMarkovTable[kPrevEl][kNextEl]
	until kAccum >= kRandom do
		kNextEl    +=         1
		kAccum     +=         kMarkovTable[kPrevEl][kNextEl]
 	enduntil
     
     xout       kNextEl
endop

;****DEFINITIONS FOR NOTES****
 ;notes as proportions and a base frequency
giNotes[]  array      1, 16/15, 9/8, 6/5, 5/4, 4/3, sqrt(2)/1, 3/2, 8/5, 5/3, 7/4, 15/8
giBasFreq  =          330
gkCurFreq  init		giBasFreq ;keep track of where we are in the progression

;KRK - modify examples 7x7 piece to be 12x12. Make it somewhat bluesy, i.e., emphasize the tonic dominant & 7th chord
giProbNotes[][] init  12, 12

;				 1!	  	   2	 	     3!    4	     	  5!		   6      m7!	7
giProbNotes array     0.10, 0.00, 0.05, 0.15, 0.10, 0.05, 0.00, 0.20, 0.00, 0.00, 0.30, 0.05, ;1
                      0.50, 0.00, 0.30, 0.00, 0.20, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 
                      0.20, 0.10, 0.00, 0.00, 0.40, 0.30, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, ;2
                      0.10, 0.00, 0.10, 0.00, 0.30, 0.00, 0.00, 0.50, 0.00, 0.00, 0.00, 0.00, 
                      0.30, 0.00, 0.10, 0.00, 0.00, 0.00, 0.00, 0.30, 0.00, 0.15, 0.15, 0.00, ;3
                      0.10, 0.00, 0.10, 0.00, 0.05, 0.00, 0.25, 0.40, 0.00, 0.00, 0.20, 0.00, ;4
                      0.00, 0.00, 0.00, 0.00, 0.00, 0.10, 0.00, 0.90, 0.00, 0.00, 0.00, 0.00, 
                      0.15, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.10, 0.00, 0.00, 0.75, 0.00, ;5
                      0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1.00, 0.00, 0.00, 0.00, 0.00, 
                      0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.50, 0.00, 0.00, 0.50, 0.00, ;6
                      0.50, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.30, 0.00, 0.15, 0.00, 0.15, ;m7
                      0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.50, 0.50                    

;****DEFINITIONS FOR DURATIONS****
 ;possible durations
gkDurs[]    array     2, 1, 1/2, 1/3, 1/6, 1/12
;probability of durations as markov matrix:
gkProbDurs[][] init   6, 6
gkProbDurs array      0.05, 0.20, 0.30, 0.45, 0.00, 0.00,
                      0.05, 0.20, 0.40, 0.20, 0.10, 0.05,
                      0.10, 0.20, 0.20, 0.70, 0.00, 0.00,
                      0.00, 0.00, 0.00, 0.00, 0.70, 0.30,
                      0.05, 0.10, 0.00, 0.20, 0.35, 0.30,
                      0.10, 0.20, 0.00, 0.40, 0.20, 0.10
                      
;Also create durations and probabilities for a bassline
gkDursBass[] array  1/2, 1/3, 1/6
gkProbDursBass[][] init 3,3
gkProbDursBass array	0.50, 0.50, 0.00,
				0.00, 0.00, 1.00,
				0.50, 0.50, 0.00

;****SET FIRST NOTE AND DURATION FOR MARKOV PROCESS****
giPrevNote init       1
gkPrevDur  init       3
giPrevNoteBass init   1
gkPrevDurBass init    0

;****INSTRUMENT FOR DURATIONS****
instr trigger_note	
	kTrig      metro      1/gkDurs[gkPrevDur]
	kTrigBass	metro		 1/gkDursBass[gkPrevDurBass]
	kTrigHiHat metro      1
	kChordTrig  metro     1 ;to track chord changes

	if kTrig == 1 then
	     event      "i", "select_note", 0, 1
		gkPrevDur  Markovk    gkProbDurs, gkPrevDur
	endif
 
	if kTrigBass == 1 then
		kRandomSil random 0, 1
		if kRandomSil < 0.85 then ;15 % chance of a rest (silence) - else a note is played
	 		event      "i", "select_note_bass", 0, 2
	 	endif
 		gkPrevDurBass Markovk  gkProbDursBass, gkPrevDurBass
	endif
 
	if kTrigHiHat == 1 then
		event "i", "hihat", 1, 0.5 ;hi hats are fixed to play on beats 2 and 4
		if gkCounter >= 48 then
			event "i", "hihat", 1.5, 0.5 ;add on the alternate beats as well
		endif
		if gkCounter >= 72 then ;start swinging on the last repeat
			event "i", "hihat", 1.33333, 0.5
			event "i", "hihat", 1.83333, 0.5
		endif
 	endif
 
	if kChordTrig == 1 then
		gkCounter += 1
		gkCurMod = gkCounter % 24 ;measures are basically in 2, so 12 bar blues = 24 "beats" in this case
		printks "Count: %d, Mod 24, %d\n", 1, gkCounter, gkCurMod
		if ((gkCurMod >=8) && (gkCurMod <= 11)) || (gkCurMod == 18) || (gkCurMod == 19) then
			gkCurFreq = giBasFreq * 4/3
		elseif (gkCurMod == 16) || (gkCurMod == 17) then
			gkCurFreq = giBasFreq * 5/3
		else
			gkCurFreq = giBasFreq
		endif
	endif
endin

;****INSTRUMENTS FOR PITCHES****
instr select_note
	;choose next note according to markov matrix and previous note
	;and write it to the global variable for (next) previous note
	giPrevNote	 Markov     giProbNotes, giPrevNote
	
	;call instr to play this note
     event_i "i", "osc", 0, 0.25, giPrevNote		
	;turn off this instrument
     turnoff
endin
  
instr select_note_bass
	;same ideas as above - just for the bass notes
	giPrevNoteBass Markov   giProbNotes, giPrevNoteBass
	event_i "i", "bass", 0, 0.5, giPrevNoteBass
	turnoff
endin
  
instr osc
	;FM generated tone for the "melody"
	iNote = p4
	kAmp adsr p3 * 0.05, p3 * .35, 0.8, p3 * 0.35
	kFreq = gkCurFreq * giNotes[iNote]
	iCpsDec = 500
	kmod linseg .48, p3/2, .5, p3/2, .5
	aSig foscil kAmp, kFreq, 1, kmod, 5, 1
	chnset aSig, "DrySignal"
endin

instr bass
	;FM generated tone for the bass line
	iNote = p4
	kFreq = gkCurFreq * giNotes[iNote] / 4
	kamp adsr p3 * 0.07, p3 * .15, 0.3, p3 * .15
	kIx linseg 1.0, p3, 10.0
	aSig foscil kamp, kFreq, 1, 1, kIx, 1
	chnset aSig, "DryBass"
endin

instr hihat
	;filtered noise for a hi-hat-like sound
	iDur = p3
	aHiHat noise 0.2, -0.1
	kEnv adsr 0.01*p3, 0.03*p3, 1, 0.75*p3
	aHiHat = kEnv * aHiHat
	aHiHat butterhp aHiHat, 1500
	chnset aHiHat, "HiHat"
	
endin

instr background
	;some more FM stuff for an interesting background
	iFreq = giNotes[0] * giBasFreq/8
	iIxMin = 1
	iIxMax = 10
	iIxInc = p3/4
	iModMin = p4
	iModMax = p5
	iModInc = p3/2
	kindx linseg iIxMin, iIxInc, iIxMax, iIxInc, iIxMin, iIxInc, iIxMax, iIxInc, iIxMin
	kMod linseg iModMin, iModInc, iModMax, iModInc, iModMin
	kModOsc oscil1 0, 5, p3
	aSig foscili 1, iFreq, 1, kModOsc, kindx, 1
	aFlang oscili 1, 5
	aSig flanger aSig, aFlang, 0.0
	
	aSig2 foscili 1, iFreq * 1.5, 1, kModOsc *1.5, kindx * -.66666, 1
	aSig = (aSig + aSig2) / 2
	
	aSigHp butterhp aSig, 8000
	aSigLp butterlp aSig, 600
	
	aSig = (aSigHp + aSigLp) / 2
	
	chnset aSig*1.5, "Background"
endin

;======= Reverb unit from last page of chapter 23 of CSound book ======
;================== (Gardner large room reverb) =======================
instr ReverbUnit
	iDur = p3
	iamp = p4
	adel71 init 0
	adel11 init 0
	adel12 init 0
	adel13 init 0
	adel31 init 0
	adel61 init 0
	adel62 init 0
	kdclick linseg 0, 0.002, iamp, iDur-0.004, iamp, 0.002, 0
		
	aSig chnget "DrySignal"
	aBk chnget "Background"
	aBass chnget "DryBass"
	
	asig0 = aSig + aBk ;ignore the bass for now
	;INITIALIZE
	aflt01	butterlp	asig0, 6000				;pre-filter left
	aflt02	butterbp	0.4*adel71, 1000, 500		;feedback filter
	asum01 = aflt01 + 0.5*aflt02					;initial mix
	
	;DOUBLE-NESTED ALLPASS
	asum11 = adel12 - .35*adel11			;first inner feedforward
	asum12 = adel13 - .45*asum11			;second inner feedforward
	aout11 = asum12 - .25*asum01			;outer feedforward
	adel11 delay asum01 + .25*aout11, .0047   ;outer feedback
	adel12 delay adel11 + .35*asum11, .0083   ;first inner feedback
	adel13 delay asum11 + .45*asum12, .022	;second inner feedback
	adel21 delay aout11, .005				;delay 1
	
	;ALLPASS 1
	asub31 = adel31-.45*adel21			;feedforward
	adel31 delay adel21 + .45*asub31, .030	;feedback
	adel41 delay asub31, .067				;delay 2
	adel51 delay .4*adel41, 0.015			;delay3
	aout51 = aflt01+adel41		
	
	;SINGLE NESTED ALLPASS
	asum61 = adel62-.35*adel61			;inner feedforward
	aout61 = asum61 - .25*aout51			;outer feedforward
	adel61 delay aout51+.25*aout61, .0292	;outer feedback
	adel62 delay adel61+.35*asum61, .0098	;inner feedback
	
	;COMBINE OUTPUTS
	aout = .5*aout11 + .5*adel41+.5*aout61
	adel71 delay aout61, .108

	chnset aout*kdclick, "RevSig"
endin

;Mixing stage
instr mixer
	iGain = 0.3
	aSig chnget "RevSig"
	aSig = aSig
	aBk chnget "Background"
	aBk = aBk * .2 ;if we do the dry background	
	aBass chnget "DryBass"
	aHiHat chnget "HiHat"
	aBass = aBass * 1.5
	kTrig metro 1
	kPanLeft oscil1 0, 0.15, 50, 1
	kPanLeft = kPanLeft + 0.5
		
	aLeft, aRight pan2 aSig, kPanLeft	
	outs (aBass + aHiHat + aLeft) *iGain, (aBass + aHiHat + aRight) *iGain
	;outs aBk, aBk
endin

</CsInstruments>
<CsScore>
f 1 0 16384 10 1 ;sine wave
f 2 0 200 7 .5 50 .75 50 .5 50 .25 50 .5 ;panning function

i "ReverbUnit" 0 96 3
i "mixer" 0 96
i "background" 0 96 10 250
i "trigger_note" 0 96
</CsScore>
</CsoundSynthesizer>
<bsbPanel>
 <label>Widgets</label>
 <objectName/>
 <x>886</x>
 <y>295</y>
 <width>320</width>
 <height>240</height>
 <visible>true</visible>
 <uuid/>
 <bgcolor mode="nobackground">
  <r>255</r>
  <g>255</g>
  <b>255</b>
 </bgcolor>
</bsbPanel>
<bsbPresets>
</bsbPresets>
