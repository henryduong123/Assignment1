% MakeSourceRelease(outdir) - Creates a LEVer source release in outdir.
% NOTE: Because of the compile and dependency copies this command takes
% a very long time to execute, if you have already compiled you can comment
% out the CompileLEVer line to reduce execution time slightly.

function MakeSourceRelease(outdir)

    % Only need this if you haven't already made a binary build
    CompileLEVer;

    recmkdir(fullfile(outdir,'bin'));
    system(['copy ' '"..\..\bin\LEVer.exe" "' fullfile(outdir,'bin') '"']);
    system(['copy ' '"..\..\bin\MTC.exe" "' fullfile(outdir,'bin') '"']);
    system(['copy ' '"..\..\bin\Segmentor.exe" "' fullfile(outdir,'bin') '"']);

    recmkdir(fullfile(outdir,'src'));
    system(['copy ' '"..\gnu gpl v3.txt" "' fullfile(outdir,'src') '"']);
    system(['copy ' '"..\LEVer_ProgManual.docx" "' fullfile(outdir,'src') '"']);

    % Copy all dependencies of LEVer and Segmentor
    recmkdir(fullfile(outdir,'src\MATLAB'));
    cd('..\MATLAB');
    cpdeps(fullfile(outdir,'src\MATLAB'), 'LEVer');
    cpdeps(fullfile(outdir,'src\MATLAB'), 'Segmentor');
    system(['copy ' '"CompileLEVer.m" "' fullfile(outdir,'src\MATLAB') '"']);
    system(['copy ' '"Properties.fig" "' fullfile(outdir,'src\MATLAB') '"']);
    system(['copy ' '"..\..\bin\MTC.exe" "' fullfile(outdir,'src\MATLAB') '"']);
    system(['copy ' '"..\..\bin\Segmentor.exe" "' fullfile(outdir,'src\MATLAB') '"']);
    cd('..\buildsrc');

    % Copy c sources
    recmkdir(fullfile(outdir,'src\c'));
    system(['copy ' '"..\c\*.sln" "' fullfile(outdir,'src\c') '"']);
    system(['copy ' '"..\c\*.vcproj" "' fullfile(outdir,'src\c') '"']);
    
    recmkdir(fullfile(outdir,'src\c\MTC'));
    system(['copy ' '"..\c\MTC\*.*" "' fullfile(outdir,'src\c\MTC') '"']);
    
    recmkdir(fullfile(outdir,'src\c\mexMAT'));
    system(['copy ' '"..\c\mexMAT\*.*" "' fullfile(outdir,'src\c\mexMAT') '"']);
end