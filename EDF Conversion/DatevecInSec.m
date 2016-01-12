function [ SumSeconds ] = DatevecInSec( y, m, d, h, mi, s )
%DatevecInSec Summary of this function goes here
%   SumSeconds = s + (mi*60) + (h*60*60) + (d*24*60*60) + ...
%    (Month2Days( m )*24*60*60) + 365*y;

SumSeconds = s + (mi*60) + (h*60*60) + (d*24*60*60) + ...
    (Month2Days( m )*24*60*60) + 365*y;



end

