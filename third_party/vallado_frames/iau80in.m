% ----------------------------------------------------------------------------
%
%                           function iau80in
%
%  this function initializes the nutation matricies needed for reduction
%    calculations. the routine needs the filename of the files as input.
%
%  author        : david vallado                  719-573-2600   27 may 2002
%
%  revisions
%                -
%
%  inputs          description                    range / units
%    iar80       - integers for fk5 1980
%    rar80       - reals for fk5 1980             rad
%
%  outputs       :
%    none
%
%  locals        :
%    convrt      - conversion factor to degrees
%    i,j         - index
%
%  coupling      :
%    none        -
%
%  references    :
%
% [iau80arr] = iau80in(infilename)
% ----------------------------------------------------------------------------- }

function [iau80arr] = iau80in(infilename)

       % ------------------------  implementation   -------------------
       % 0.0001" to rad
       convrt= 0.0001 * pi / (180*3600.0);

       iau80arr = struct('rar80',zeros(106, 4), 'iar80',zeros(106, 5));

       nut80 = load(append(infilename, 'nut80.dat'));

       iau80arr.iar80 = nut80(:,1:5);
       iau80arr.rar80 = nut80(:,6:9);

       for i = 1:106
           for j = 1:4
               iau80arr.rar80(i,j)= iau80arr.rar80(i,j) * convrt;
           end
       end

