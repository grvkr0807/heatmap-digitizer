%% Take a thermal RGB image from the FLIR One camera and uses the embedded color bar to determine temperatures from the colors and make a temperature image.
clc;    % Clear the command window.
close all;  % Close all figures (except those of imtool.)
clear;  % Erase all existing variables. Or clearvars if you want.
workspace;  % Make sure the workspace panel is showing.
format long g;
format compact;
fontSize = 15;

%% ===============================================================================
% Get the name of the image the user wants to use.
baseFileName = 'Screenshot.png'; % Base file name with no folder prepended (yet).
% Get the full filename, with path prepended.
folder = pwd; % Change to whatever folder the image lives in.
fullFileName = fullfile(folder, baseFileName);  % Append base filename to folder to get the full file name.
if ~isfile(fullFileName)
	errorMessage = sprintf('Error: file not found:\n%s', fullFileName)
	uiwait(errordlg(errorMessage));
	return;
end
fprintf('Transforming image "%s" to a thermal image.\n', fullFileName);

%% ===============================================================================
% Read the image.
originalRGBImage = imread(fullFileName);
[rows, columns, numberOfColorChannels] = size(originalRGBImage)
% Display the image.
subplot(2, 3, 1);
imshow(originalRGBImage, []);
axis on;
caption = sprintf('Original Pseudocolor Image, %s', baseFileName);
title(caption, 'FontSize', fontSize, 'Interpreter', 'None');
xlabel('Column', 'FontSize', fontSize, 'Interpreter', 'None');
ylabel('Row', 'FontSize', fontSize, 'Interpreter', 'None');
drawnow;

grayImage = min(originalRGBImage, [], 3); % Useful for finding image and color map regions of image.

%% =========================================================================================================
% Need to crop out the image and the color bar separately.
% First crop out the image.
imageRow1 = 23;
imageRow2 = 264;
imageCol1 = 84;
imageCol2 = 242;
% Validate these numbers.  Often users don't adjust these in the demo for their particular image.
if imageRow2 > rows || imageCol2 > columns
	warningMessage = sprintf('Error: you are trying to extract the thermal scene image\nfrom an area outside the actual image.\nThe size of the full image is %d rows by %d columns.\nYou are trying to extract from row %d to %d, and from column %d to %d, which is outside the image.',...
		rows, columns, imageRow1, imageRow2, imageCol1, imageCol2);
	uiwait(warndlg(warningMessage));
	% Clip the coordinates so they fit.
	imageRow1 = min(imageRow1, rows);
	imageRow2 = min(imageRow2, rows);
	imageCol1 = min(imageCol1, column);
	imageCol2 = min(imageCol2, column);
end
% Put up a rectangle over the original image showing where we cropped out of.
rectanglePosition = [imageCol1, imageRow1, imageCol2 - imageCol1, imageRow2 - imageRow1];
hold on;
rectangle('Position', rectanglePosition, 'EdgeColor', 'r', 'LineWidth', 2);
% Crop off the surrounding clutter to get the RGB image.
rgbImage = originalRGBImage(imageRow1 : imageRow2, imageCol1 : imageCol2, :);

% Next, crop out the colorbar.  Define the location for this particular image.
colorBarRow1 = 23;
colorBarRow2 = 264;
colorBarCol1 = 267;
colorBarCol2 = 283;
% Put up a rectangle over the original image showing where we cropped out of.
rectanglePosition = [colorBarCol1, colorBarRow1, colorBarCol2 - colorBarCol1, colorBarRow2 - colorBarRow1];
hold on;
rectangle('Position', rectanglePosition, 'EdgeColor', 'r', 'LineWidth', 2);
% Crop off the surrounding clutter to get the colorbar.
colorBarImage = originalRGBImage(colorBarRow1 : colorBarRow2, colorBarCol1 : colorBarCol2, :);
b = colorBarImage(:,:,3);

%% =========================================================================================================
% Display the pseudocolored RGB image.
subplot(2, 3, 2);
imshow(rgbImage, []);
axis on;
caption = sprintf('Cropped Pseudocolor Image');
title(caption, 'FontSize', fontSize, 'Interpreter', 'None');
xlabel('Column', 'FontSize', fontSize, 'Interpreter', 'None');
ylabel('Row', 'FontSize', fontSize, 'Interpreter', 'None');
drawnow;
hp = impixelinfo();

% Display the colorbar image.
subplot(2, 3, 3);
imshow(colorBarImage, []);
axis on;
impixelinfo;
caption = sprintf('Cropped Colorbar Image');
title(caption, 'FontSize', fontSize, 'Interpreter', 'None');
xlabel('Column', 'FontSize', fontSize, 'Interpreter', 'None');
ylabel('Row', 'FontSize', fontSize, 'Interpreter', 'None');
drawnow;

% Set up figure properties:
% Enlarge figure to full screen.
g = gcf;
g.WindowState = 'maximized';
% Get rid of tool bar and pulldown menus that are along top of figure.
% set(gcf, 'Toolbar', 'none', 'Menu', 'none');
% Give a name to the title bar.
g.Name = 'Demo by ImageAnalyst';
g.NumberTitle = 'Off';

%% =========================================================================================================
% Get the color map from the color bar image.
storedColorMap = colorBarImage(:,1,:);
% Need to call squeeze to get it from a 3D matrix to a 2-D matrix.
% Also need to divide by 255 since colormap values must be between 0 and 1.
storedColorMap = double(squeeze(storedColorMap)) / 255;
% Need to flip up/down because the low rows are the high temperatures, not the low temperatures.
storedColorMap = flipud(storedColorMap);

% Convert the subject/sample from a pseudocolored RGB image to a grayscale, indexed image.
indexedImage = rgb2ind(rgbImage, storedColorMap);
% Display the indexed image.
subplot(2, 3, 4);
imshow(indexedImage, []);
impixelinfo;
axis on;
caption = sprintf('Indexed Image (Gray Scale Thermal Image)');
title(caption, 'FontSize', fontSize, 'Interpreter', 'None');
xlabel('Column', 'FontSize', fontSize, 'Interpreter', 'None');
ylabel('Row', 'FontSize', fontSize, 'Interpreter', 'None');
drawnow;

%% ========================================================================================================================================
% Now we need to define the temperatures at the end of the colored temperature scale.
% You can read these off of the image, since we can't figure them out without doing OCR on the image.
% Define the temperature at the top end of the scale.
% This will probably be the high temperature.
highTemp = 6455;
% Define the temperature at the dark end of the scale
% This will probably be the low temperature.
lowTemp = 30;

%% ========================================================================================================================================
% Optional : ask the user to confirm these two numbers.
% Ask user for two floating point numbers.
defaultValue = {sprintf('%.1f', highTemp), sprintf('%.1f', lowTemp)};
titleBar = 'Enter temperature range';
userPrompt = {'Enter max temp at top of colorbar : ', 'Enter min temp at bottom of color bar: '};
caUserInput = inputdlg(userPrompt, titleBar, 1, defaultValue);
if isempty(caUserInput),return,end % Bail out if they clicked Cancel.
% Convert to floating point from string.
highTemp = str2double(caUserInput{1});
lowTemp = str2double(caUserInput{2});
% Check highTemp for validity.
if isnan(highTemp)
	% They didn't enter a number.
	% They clicked Cancel, or entered a character, symbols, or something else not allowed.
	% Convert the default from a string and stick that into usersValue1.
	highTemp = str2double(defaultValue{1});
	message = sprintf('I said it had to be a number.\nTry replacing the user.\nI will use %.2f and continue.', highTemp);
	uiwait(warndlg(message));
end
% Do the same for lowTemp
% Check usersValue2 for validity.
if isnan(lowTemp)
	% They didn't enter a number.
	% They clicked Cancel, or entered a character, symbols, or something else not allowed.
	% Convert the default from a string and stick that into usersValue2.
	lowTemp = str2double(defaultValue{2});
	message = sprintf('I said it had to be a number.\nTry replacing the user.\nI will use %.2f and continue.', lowTemp);
	uiwait(warndlg(message));
end

%% ========================================================================================================================================
% Scale the indexed gray scale image so that it's actual temperatures in degrees C instead of in gray scale indexes.
thermalImage = lowTemp + (highTemp - lowTemp) * mat2gray(indexedImage);

% Display the thermal image.
subplot(2, 3, 5);
imshow(thermalImage, []);
axis on;
colorbar;
title('Floating Point Thermal (Temperature) Image', 'FontSize', fontSize, 'Interpreter', 'None');
xlabel('Column', 'FontSize', fontSize, 'Interpreter', 'None');
ylabel('Row', 'FontSize', fontSize, 'Interpreter', 'None');

% Let user mouse around and see temperatures on the GUI under the temperature image.
hp = impixelinfo();
hp.Units = 'normalized';
hp.Position = [0.45, 0.03, 0.25, 0.02];

%% =========================================================================================================
% Get and display the histogram of the thermal image.
subplot(2, 3, 6);
histogram(thermalImage, 'Normalization', 'probability');
axis on;
grid on;
caption = sprintf('Histogram of Thermal Image');
title(caption, 'FontSize', fontSize, 'Interpreter', 'None');
xlabel('Temperature [Degrees]', 'FontSize', fontSize, 'Interpreter', 'None');
ylabel('Frequency [Pixel Count]', 'FontSize', fontSize, 'Interpreter', 'None');

% Get the maximum temperature.
maxTemperature = max(thermalImage(:));
fprintf('The maximum temperature in the image is %.2f\n', maxTemperature);
fprintf('Done!  Thanks Image Analyst!\n');

%% =========================================================================================================
% Extract data from center of each cell

[Nrows, Ncols]= size(thermalImage);   % number of pixels of data along rows and columns
data_rows= 9;   % number of actual data blocks along rows to be extracted
data_cols= 4;   % number of actual data blocks along columns to be extracted
len_row= Nrows/data_rows;   % number of pixels that span each data plock along the rows
len_col= Ncols/data_cols;   % number of pixels that span each data plock along the columns

extracted_data= zeros(data_rows, data_cols);

% % Extract data from the center of each block
% for irow= 1:data_rows
%     for icol= 1:data_cols
% 
%         row_index= round((irow- 0.5)*len_row);
%         col_index= round((icol- 0.5)*len_col);
% 
%         extracted_data(irow, icol)= thermalImage(row_index, col_index);
% 
%     end
% end

% Extract data based on frequency as grayscale can be patchy
for irow= 1:data_rows
    for icol= 1:data_cols

        row_start= round(len_row*(irow-1)+1);
        row_end= round(len_row*(irow));
        col_start= round(len_col*(icol-1)+1);
        col_end= round(len_col*(icol));

        extracted_data(irow, icol)= mode(thermalImage(row_start:row_end, col_start:col_end), 'all');

    end
end



