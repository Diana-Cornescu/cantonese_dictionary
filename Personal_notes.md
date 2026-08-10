I've confirmed this now works on Desktop and on mobile. There are a few edits I'd like you to make.

Edits:
remove of the tag boxes in the row-view that are displayed below the character text preview.
Include a the tags for the character to be instead inside the character screen. Have them display as rounded not square boxes similar to how the flashcard buttons are like.
Have both the Notes section and the Tags section to below the Flashcard section.
Please make the star/fav icon to turn yellow when active not just gray.
Change the text of accuracy % stat to be colored red if below 40%, yellow if below 70% and green if above 70%.
Along with the back button I also need a home button to get to the row view screen.
Instead of a intermediate screen to instruct if flashcards should be normal or "hard mode", instead have toggle at top for hard (on/off). Have a default to be all characters unless otherwise toggled and for every fresh launch.
For the archive screen, instead of having it as a button to select or select that screen, please use an back arrow  and a title to the screen that this is an archived view that this is a archive screen -instead of re-clicking the icon (similar to the flash card screen)
Remove the archive and the delete icons on the character row view, instead move them within the character screen at the very bottom. As a result only have the the star and hard indicators on the left in the row view and please minimize the padding btw them a bit.\



Happy with the UI changes you recently made. There are a still a few edits and discussions I'd like to have.
the flashcard icon in the top right area is better now, but is it possible to have it turned 90 degrees clockwise? Or a different Icon similar to that if you can't rotate it. that's more what I was imagining.
Right now the text version is mandatory but that's more involved than I'd like. Can we instead just have the handwritten be the only mandatory one. Since the row screen uses a text version as it's preview, please auto-fill in the textbox with "?" if nothing else is provided. That also means however, that the text books need to be allowed to be edited.
I need clarity on where and how you storing the images. what's standard in applications like this? If its the cantonese_dictionary_data file can it be maybe rename it to be more clear? That its the cords for image recreation or something.
I've noticed that, at least on the desktop, that the drawing can overflow. The image should probability be constrain in it's display.
The buttons on the end of the character screen (archive and delete) are too low - they are getting hidden behind the Android: back, home, tabs bar at the bottom. Is there a smart way to consider that beyond just added the padding or is that just the standard?

--- 
???
how is it to make it official/proper with not needing a connection

what's the weird debug corner banner - get rid of .. or is a flutter thing? double check.

I feel like I should have control over where to export the export. What's standard? Consider that this will be on android (I know you shouldn't put the state of an app into the app files - since the running application should not be editing itself).

SQL:
feature: gallery of photos of characters seen out and about - for different font identification. (small tho - or)
SQL conversions

2nd prio:
can create a very long redundant history to back track with current "back"-"log" set up. need to minimize it somehow (not critical / future fix)

I want flash card stats to have a different styling and come after the definition. the stuling I want to be more like boxes seen & accuracry on the first row of boxes, followed by the correct and incorrect absolute values and the last reviewed as a line before all of thes boxes centered