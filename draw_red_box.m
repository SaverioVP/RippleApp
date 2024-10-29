function draw_red_box(axesHandle, start_time, end_time, y_start, y_end, label_number)
    % Define the x and y coordinates of the box
    xBox = [start_time, end_time, end_time, start_time];
    yBox = [y_start, y_start, y_end, y_end];

    hold(axesHandle, 'on'); 
    % Draw red box around ripple
    fill(xBox, yBox, 'r','FaceAlpha', 0.5, 'EdgeColor', 'none', 'Parent', axesHandle, ...
         'HandleVisibility', 'off');

    hold(axesHandle, 'off'); 

end