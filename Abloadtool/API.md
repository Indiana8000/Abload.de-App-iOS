#  API Documentation

## URLs

API: https://www.abload.de/api/
Images: https://www.abload.de/$Type$/

Types:
- mini (64px × 64px white)
- thumb (132px × 147px black subtitle)
- thumb2 (132px × 132px black)

## Calls

### login

-> name
-> password

<- status (code 801 = OK)
<- login
<- motd


### user

-> session

<- status (code 801 = OK)
<- login
<- motd
<- galleries
<- lastimages


### upload

-> session
-> gallery
-> img0 (increment number for multiple files)

<- status (Optional; Only set on Error)
~~<- login~~
~~<- motd~~
<- images (only uploaded)


### gallery/list

-> session

<- status (Optional; Only set on Error)
<- login
<- motd
<- galleries
<- lastimages


### gallery/new

-> session
-> name
-> desc

<- status (code 605 = OK)
~~<- login~~
~~<- motd~~
~~<- galleries~~
~~<- lastimages~~


### gallery/del

-> session
-> gid
-> img (Optional; 1 = delete all images in the Gallery)

<- status (code 608 & 609 = OK)
~~<- login~~
~~<- motd~~
<- galleries
<- lastimages


### images

-> session
-> gid (Optional; Internal ID, not the KEY)

<- status (Optional; Only set on Error)
~~<- login~~
~~<- motd~~
<- images


### image/del
-> session
-> filename

<- status (code 703 = OK)
~~<- login~~
~~<- motd~~
<- lastimages (if one of the last 5 got deleted!)


## Status-Code

### General

401 - Du musst eingeloggt sein um die API zu benutzen.
402 - Dein Account ist gesperrt.
404 - Fehler: Dieser API Aufruf ist nicht bekannt.
405 - Dieser User-Agent ist der API nicht bekannt.


### gallery/new
601 - Kein Name angegeben.
602 - Name zu lang.
603 - Beschreibung zu lang.
604 - Eine Galerie mit diesem Namen existiert bereits.
605 - Galerie erfolgreich angelegt.


### gallery/del
606 - Galerie ID muss numerisch sein.
607 - Galerie ID Existiert nicht.
608 - Galerie ID gelöscht.
609 - Galerie ID und Bilder gelöscht.


### image/del
701 - Kein Name angegeben.
702 - Ungueltiger Dateiname angegeben.
703 - Bild geloescht.
704 - Bild existiert nicht oder gehört dir nicht.


### login
801 - Du wurdest erfolgreich Eingeloggt.


### upload
901 - Der Upload war erfolgreich.

