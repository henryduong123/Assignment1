function x_clamped = Clamp(x, minval, maxval)
    x_clamped = max(cat(3,x,minval*ones(size(x))),[],3);
    x_clamped = min(cat(3,x_clamped,maxval*ones(size(x))),[],3);
end