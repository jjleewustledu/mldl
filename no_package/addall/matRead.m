
function data = matRead(filename)
inp = load(filename);
f = fields(inp);
data = inp.(f{1});
d = data(:);
d1 = d(d~=0);
m = mean(d1(:));
for i = 1:size(data,1)
    for j = 1:size(data,2)
        for k = 1:size(data,3)
            if(data(i,j,k) ~= 0)
                data(i,j,k) = (data(i,j,k)-m);                
            end
        end
    end
end
end