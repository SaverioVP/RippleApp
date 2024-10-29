function draw_green_box(axesHandle, start_time, end_time, y_start, y_end, label_number)
    % Define the x and y coordinates of the box
    xBox = [start_time, end_time, end_time, start_time];
    yBox = [y_start, y_start, y_end, y_end];

    hold(axesHandle, 'on'); 

    % Draw green box
    fill(xBox, yBox, 'g', 'FaceAlpha', 0.3, 'EdgeColor', 'none', 'Parent', axesHandle, ...
     'HandleVisibility', 'off');
    % Write label number
    text(end_time, y_end, num2str(label_number), 'VerticalAlignment', 'top', 'HorizontalAlignment', 'right', ...
        'FontSize', 10, 'FontWeight', 'bold', 'Color', 'k', 'Parent', axesHandle);

    hold(axesHandle, 'off'); 

end