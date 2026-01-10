
u = linspace(-2,2,101);

for i = 1: numel(u)
    y(i) = fcn(u(i),1,0);
end

figure
plot(u,y)
grid on

function y = fcn(u,limit,activate)
y = u ...
    + (sign(u)*limit - u) * (abs(u) >= limit) * activate;
end