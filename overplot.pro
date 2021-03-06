pro overplot, spectrum,xr_key=xrnge, object_key=object, ps_key=ps, gemini_key=gem, lris_key=lris, file_key=file_key,ms=ms,sec=sec, small=small, giants=giants,young=young,ylog=ylog, dered=dered, noisy=noisy

;+
; NAME:
;	OVERPLOT
;
; PURPOSE:
;       Creates plots of observed spectra with spectral standards overplotted
;
; CALLING SEQUENCE:
;
;	OVERPLOT, Filename, [ xr= , /ps, /Gemini,/Ms, /mine,/giants ]
;
; INPUTS:
;	Filename: String containing name of FITS file to be compared
;	          to spectral standards.
;
; OPTIONAL INPUTS:
;	xr: Two-element array with desired xrange of plot.
;           Default is 6000-11000 Angstroms.
;
; KEYWORD PARAMETERS:
;	PS:     Set this keyword to get postscript output
;
;	GEMINI:	Set this keyword to compare to Gemini standards
;	instead of LRIS
;
; OUTPUTS:
;       Displays to the screen the data (black) and spectral standard
;       in red.
;
; OPTIONAL OUTPUTS:
;	If the PS keyword is set, a postscript file will be generated.
;
; RESTRICTIONS:
;	Describe any "restrictions" here.  Delete this section if there are
;	no important restrictions.
;
; ROUTINES CALLED:
;       READFITS
;       SXPAR
;       AVGFLUX
; 
; EXAMPLE:
;	Please provide a simple example here. An example from the PICKFILE
;	documentation is shown below. Please try to include examples that
;       do not rely on variables or data files that are not defined in
;       the example code. Your example should execute properly if typed
;       in at the IDL command line with no other preparation.
;
;	Create a PICKFILE widget that lets users select only files with 
;	the extensions 'pro' and 'dat'.  Use the 'Select File to Read' title 
;	and store the name of the selected file in the variable F.  Enter:
;
;		F = PICKFILE(/READ, FILTER = ['pro', 'dat'])
;
; FUTURE MODIFICATIONS:
;
; MODIFICATION HISTORY:
; 	Written by:	Kelle Cruz, July 2005
;       Added /ylog keyword for display to screen. did not implement
;          for PS output. KLC, June 2008 
;-


IF N_params() lt 1 then begin
     print,"Syntax - overplot, 'file.fits' (, xr=, /ps,/gem,,/lris,/M, /sec,/giants,/young,/small,/file)"
     print,'xr=[x1,x2] to set xrange'
     print, '/ylog to plot logarithmic'
     print, ''
     print,'/gem to compare to gemini stds'     
     print,'/lris to compare to LRIS data'     
     print, '/Ms to overplot M dwarfs instead of L dwarfs'     
     print,'/giants to compare to giants'     
     print,'/young to compare to young standards'    
     print,'/sec to use secondary stds'     
     print, ''
     print,'/ps to produce postscript output'
     print, '/file to use filename instead of object name in header'
     print, '/small for small postscript output for lab notebook'
     print, ''
     return
ENDIF


if file_test('/Users/kelle/Dropbox/Data/optical_spectra/') then root_opt='/Users/kelle/Dropbox/Data/optical_spectra/' $
else root_opt='/scr4/optical_spectra/'

IF ~file_test(spectrum) then spectrum=root_opt+spectrum

;spectrum=spectrum+'.fits'
IF ~file_test(spectrum) then begin
    print, 'File does not exist:' + spectrum
    return
endif

if ~ Keyword_set(xrnge) then xrnge=[6000,9800]
if ~ Keyword_set(ylog) then ylog=0

if file_test('/Users/kelle/Dropbox/Data/optical_spectra/standards/') then root1='/Users/kelle/Dropbox/Data/optical_spectra/standards/' $
else root1='/scr4/optical_spectra/standards/'
;Make MINE default
IF  keyword_set(gem) OR  keyword_set(lris) OR  keyword_set(sec)  OR keyword_set(young) THEN BEGIN
    IF keyword_set(gem) THEN root=root1+ 'gemini/'
    IF keyword_set(lris) THEN root=root1+'lris/'
    IF keyword_set(sec) THEN root=root1+'mine/dwarfs/secondary_stds/'
    IF keyword_set(young) THEN root=root1+'young_stds/'
ENDIF ELSE BEGIN
    root=root1+'mine/dwarfs/primary_stds/'
ENDELSE

IF keyword_set(Ms) or keyword_set(giants) THEN begin
    data=KREADSPEC(spectrum,h,num,/norm,/M)
ENDIF ELSE begin
    data=KREADSPEC(spectrum,h,num,/norm)
ENDELSE
spec=data[1,*]
w=data[0,*]

;deredden if necessary
if keyword_set(dered) then ccm_unred,w,spec,dered,spec2

telescope = sxpar(h,'TELESCOP')
date_obs = sxpar(h,'DATE-OBS',/silent)
if size(date_obs,/type) ne 7 then date_obs='' ; use empty string if no obs date in header
if size(telescope,/type) ne 7 then telescope='' ; use empty string if no telescope in header


if ~keyword_set(object) then object=strtrim(sxpar(h,'OBJECT'),2)
if object eq '0' then file_key = 1 ;use filename if no object name in header
file_name=(strsplit(file_basename(spectrum),'.',/extract))[0]
IF keyword_set(file_key) then object= file_name
            

IF keyword_set(Ms) THEN begin
   stds=file_search(root+'*_[F,G,K,M]*.fits', count=nfiles)
   ;pos=transpose(strpos(stds,'_M'))
   pos=transpose(strpos(stds,'.fits'))
ENDIF 

IF ~keyword_set(Ms) and  ~keyword_set(giants) then begin
   stds=file_search(root+'*_[L,T]?*.fits', count=nfiles)
   pos=transpose(strpos(stds,'_L'))
ENDif

if keyword_set(young) then begin
    IF keyword_set(Ms) THEN stds=file_search(root+'*_[M]?*.fits', count=nfiles) ELSE $
      stds=file_search(root+'*_[L]?*.fits', count=nfiles)
    pos=transpose(strpos(stds,'_',/REVERSE_SEARCH))
endif

if keyword_set(giants) then begin
    root='/scr/kelle/optical_spectra/standards/mine/giants/'
    stds=file_search(root+'*_[K,M,L]?*.fits', count=nfiles)
    pos=transpose(strpos(stds,'_',/REVERSE_SEARCH))
endif

IF keyword_set(Ms) THEN begin
    s=sort(strmid(stds,pos-2,2)) 
ENDIF ELSE BEGIN
    IF keyword_set(giants) OR  keyword_set(young) THEN  s=sort(strmid(stds,pos+1,3)) ELSE s=sort(strmid(stds,pos+2,2))
ENDELSE
IF keyword_set(Ms) AND  keyword_set(young) THEN  s=sort(strmid(stds,pos+2,2))


stds=stds[s]

PRINT, 'Which do you want to overplot?: '
FOR m=0, nfiles-1 do begin
	print, strn(m)+') '+ FILE_BASENAME(stds[m],'.fits')
ENDFOR
READ, use_file, PROMPT='Enter number of spectrum to overplot: '
IF Keyword_set(ps) THEN READ, use_file2, PROMPT='Enter number of second spectrum to compare: ' else use_file2=0

IF keyword_set(Ms) THEN begin
    data2=KREADSPEC(stds[use_file],h2,/M,/norm,/silent)
    data3=KREADSPEC(stds[use_file2],h3,/M,/norm,/silent)
ENDIF ELSE begin
    data2=KREADSPEC(stds[use_file],h2,/norm,/silent)
    data3=KREADSPEC(stds[use_file2],h3,/norm,/silent)
ENDELSE

std=data2[1,*]
w2=data2[0,*]

std2=data3[1,*]
w3=data3[0,*]

std_name=file_basename(stds[use_file])
telescope_std = sxpar(h2,'TELESCOP')
date_obs_std = sxpar(h2,'DATE-OBS',count=datecount,/silent)

std_name2=file_basename(stds[use_file2])
telescope_std2 = sxpar(h3,'TELESCOP')
date_obs_std2 = sxpar(h3,'DATE-OBS',count=datecount,/silent)

if SIZE(telescope_std,/TNAME) eq 'INT' then telescope_std=''
if SIZE(telescope_std2,/TNAME) eq 'INT' then telescope_std2=''
if SIZE(date_obs_std,/TNAME) eq 'INT' then date_obs_std=''
if SIZE(date_obs_std2,/TNAME) eq 'INT' then date_obs_std2=''

flux_unit=SXPAR(h,'BUNIT', count=fluxcount)
if size(flux_unit,/tname) eq 'INT' then flux_unit='Normalized Flux'

@colors_kc
;red=150
color_line = black
IF ~KEYWORD_SET(ps) THEN BEGIN
	;set up for display to screen
    set_plot,'x'
    device, Decomposed=0 ;make colors work for 24-bit display
	print,'ye'
    color_line=white ;exchange colors to work with default black backround
    @symbols_kc ;load string symbols and greek letters for Hershey
    cs=2 ;charcter size
	;aspect_ratio=1.5
    ;window, 2, xsize=xsize_window, ysize=xsize_window*aspect_ratio ;,xpos=0,ypos=0
ENDIF

if keyword_set(ylog) then yrange=[1e-4,2] else yrange=[0,2]

plot, w, spec, xr=xrnge,yr=yrange, xstyle=1, thick=1.0,ylog=ylog,ystyle=1, color=color_line,/nodata
if ~keyword_set(noisy) then begin
	oplot, w2, std, color=red , thick=1;red
	oplot,w,spec, thick=1,color=color_line
endif else begin
	oplot,w,spec, thick=1,color=color_line
	oplot, w2, std, color=red , thick=2;red
endelse
oplot, [6708,6708],[0,5], linestyle=1

if keyword_set(dered) then oplot,w,spec2, color=orange

xyouts, 0.12, 0.55 ,object, /normal, charsize=2
xyouts, 0.12, 0.5, telescope+'!C'+date_obs, /normal, align=0

xyouts, 0.12, 0.9, 'STD: '+std_name +'!C' + telescope_std, /normal, align=0

IF Keyword_set(ps) THEN BEGIN
	!p.font=0
	 set_plot, 'ps'
	@symbols_ps_kc ;
	 device, encapsulated=0, /helvetica, /color

  if keyword_set(small) then begin
	fn=root_opt+object+'_oversm.ps'
      device, filename=fn, xsize=10.5/2, ysize=8.0/2,/inches,landscape=0, xoffset=0, yoffset=0.5
      xt=0.2
  ENDIF else begin
	fn=root_opt+object+'_over.ps'      
	device, filename=fn, landscape=1, xsize=10.5, ysize=8.0,/inches, xoffset=0.2, yoffset=11
      xt=0.12
  endelse

  o1=0.5
  o2=o1+1.2
  o3=o2+1.2
  o4=o3+1.2

  w_plot=where(w2 ge xrnge[0] and w2 le xrnge[1])

  ym=max(std[w_plot]+o4)


  xts=min(xrnge)+200

;TOP
  plot, w2,std+o4, xr=xrnge, yr=[0,ym],xstyle=1, ystyle=1,xtitle='Wavelength '+'('+angstrom+')',ytitle='Flux ('+flux_unit+')'

  xyouts, xts, o4+0.5, 'STD: '+std_name +'!C' + telescope_std , align=0

;MIDDLE OVERPLOT
  oplot, w, spec+o3, thick=2.0
  oplot, w2, std+o3, color=red    ;red

;MIDDLE DATA
  oplot, w, spec+o2 ;middle

;BOTTOM STD2
  oplot, w3,std2+o1 ;bottom
  xyouts, xts, o1+0.5, 'STD: '+std_name2 +'!C' + telescope_std2 , align=0

;LABELS
  xyouts, xts, o2+0.7 ,object,charsize=2
  xyouts, xt, 0.9, telescope+'!C'+date_obs, /normal, align=0
 
;  xyouts, xt, 0.85, 'STD: '+std_name +'!C' + telescope_std , /normal, align=0
 
  if keyword_set(giants) then begin
      feat, 1.2, /lowg
  endif else begin
      feat, 1.2
  endelse

  device, /close
  set_plot,'x'

  message,'WROTE:'+fn,/info

ENDIF

END

PRO feat, shift,lowg=lowg

; FEAT, [shift , /lowg]

IF n_elements(shift) EQ 0 THEN shift=0

;Halpha
xyouts, 6530, 0.8+shift, 'H!9a!X';, charsize=1.2
oplot, [6563,6563],[0.9,1.7]+shift, linestyle=1 
oplot, [6563,6563],[0.0,0.7]+shift, linestyle=1 

;Li
xyouts, 6680, 1.3+shift, 'Li !7I!X';, charsize=1.2
oplot, [6708,6708],[0.0,1.1]+shift, linestyle=1

;K I
xyouts, 7650, 1.1+shift, 'K !7I!X';, charsize=1.2

oplot, [7665,7665],[1.0,1.7]+shift, linestyle =1
oplot, [7699,7699],[1.0,1.7]+shift, linestyle =1

;Rb I
xyouts, 7790, 1.1+shift, 'Rb !7I!X';, charsize=1.2
xyouts, 7930, 1.1+shift, 'Rb !7I!X';, charsize=1.2

oplot, [7800,7800],[1.0,1.7]+shift, linestyle =1
oplot, [7948,7948],[1.0,1.7]+shift, linestyle =1


;Na I
oplot, [8183,8183],[1.4,2.3]+shift, linestyle =1
oplot, [8195,8195],[1.4,2.3]+shift, linestyle =1

oplot, [8183,8183],[0.4,1.2]+shift, linestyle =1
oplot, [8195,8195],[0.4,1.2]+shift, linestyle =1

xyouts, 8145, 0.8+shift, 'Na !7I!X';, charsize=1.2

;Cs I
xyouts, 8520, 0.8+shift, 'Cs !7I!X', align=0.5;, charsize=1.2
xyouts, 8940, 0.8+shift, 'Cs !7I!X', align=0.5;, charsize=1.2

oplot, [8521,8521],[1.0,1.7]+shift, linestyle =1
oplot, [8943,8943],[1.0,1.7]+shift, linestyle =1


;GIANTS and YOUNG

IF keyword_set(lowg) THEN begin

;print, 'lowg'

;VO
oplot, [7334, 7334, 7534,7534],[1.25,1.3,1.3,1.25]-shift
oplot, [7851,7851,7973,7973],[1.25,1.3,1.3,1.25]-shift
xyouts, 7334, 1.35-shift, 'VO'
xyouts, 7851, 1.35-shift, 'VO'


;K I doublet
;oplot, [7665,7665],[1.2,1.4], linestyle=1
;oplot, [7699,7699],[1.25,1.45], linestyle=1

;Ca II triplet
oplot, [8498,8498],[1.0,1.95]+shift, linestyle=1
oplot, [8542,8542],[1.0,1.95]+shift, linestyle=1
oplot, [8662,8662],[1.0,1.95]+shift, linestyle=1
xyouts, 8490, 2.0+shift, 'Ca !7II!X'



ENDIF

END

