function addSlide2PPT(fig_handle , presentation_path_in    ...
                                  , slide_number , position ...
                                  , presentation_path_out)

%%
% the fig_handle input is a handle to the figure in which you want to insert
% into the PPT file

% the presentation_path_in input is the directory including the filename to 
% the presentation that you wish to modify

% the presentation_path_out input is the output directory including the 
% filename.  Optional 

% The position input is a vector of four elements that describe how the
% image will be placed in the slide
% position = [x_position y_position width height]

% slide_number is the number of the slide to be inserted

%% Open PowerPoint as a COM Automation server
h = actxserver('PowerPoint.Application');
% Show the PowerPoint window
h.Visible = 1;

%% ADD PRESENTATION
% View the methods that can be invoked
% h.Presentation.invoke

% Open a presentation via "Open" method
Presentation = h.Presentation.Open(presentation_path_in);
% The command below opens a new presentation
% Presentation = h.Presentation.Add();

%% ADD SLIDE
% View the methods that can be invoked
% Presentation.Slides.invoke

% Add a slide via "AddSlide" method with a blank slide
blankSlide = Presentation.SlideMaster.CustomLayouts.Item(7);
% Get the number of slides in the presentation
slide_count = get(Presentation.Slides,'Count');

if slide_number < slide_count + 1
    %if true add slide normally
    Slide = Presentation.Slides.AddSlide(slide_number,blankSlide);
else
    %otherwise create slides until the desired slide num is equal to the
    %slide count
    while slide_number >= slide_count + 1 
        Slide = Presentation.Slides.AddSlide(slide_count + 1,blankSlide);
        slide_count = get(Presentation.Slides,'Count');
    end
end


%% GENERATE MATLAB IMAGES
print(fig_handle ,'-dpng', 'img.png');
%-dpng is an argument to print the image as a PNG file
%more information on the print command, including optional input
%paramenters can be found in the link below

%http://www.mathworks.com/help/matlab/ref/print.html

% Note: it is still necessary to save these files to disk, and then import
% them into PowerPoint from a disk file, because PowerPoint does not
% understand MATLAB data types. However, we can script this all from
% MATLAB.

%% ADD IMAGES TO SLIDES 
% Note: Change the last four numbers to modify the position and size of 
% the image in the slide
Slide.Shapes.AddPicture([pwd '\' 'img.png'], 'msoFalse'  ,'msoTrue'    ...
                                 , position(1) , position(2)           ...
                                 , position(3) , position(4)           );
                             
%% SAVE PRESENTATION
% If you would rather save the PowerPoint manually you can leave out the
% optional presentation_path_out variable
% Presentation.SaveAs(presentation_path_out)
if nargin == 5
    Presentation.SaveAs(presentation_path_out)
end

%% Close PowerPoint as a COM Automation server
%h.delete;

