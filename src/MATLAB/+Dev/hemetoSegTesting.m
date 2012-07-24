orgImg = imread('C:\Users\Eric\Pictures\Pos18\Pos18\Doc_0008_2_Position18.tif_Files_cropped\120608ML_p018_t00637_w0.tif');
gry = mat2gray(orgImg);
thGry = graythresh(gry);
bwGry = im2bw(gry,thGry);
se=strel('disk',2);
gd=imdilate(gry,se);
ge=imerode(gry,se);
ig=gd-ge;

thIg = graythresh(ig);
bwig=im2bw(ig,thIg);

% gry_ig=bwGry-bwig;
% gry_ig(:)=max(gry_ig(:),0);
% ds = bwdist(bwig);

bw = bwGry &~ bwig;
bw2 = +bwGry;
bw2 = bw2-ig;

bw3 = imfill(bw,'holes');
% bw3 = imopen(bw3,se);

[bwR bwC] = find(bwGry);
imagesc(gry);colormap gray, hold on
plot(bwC,bwR,'sb');

CC = bwconncomp(bw3,8);
stats = regionprops(CC, 'Area', 'Centroid', 'Eccentricity','MinorAxisLength');
idx = find([stats.Area] > 100);
for i=1:length(idx)
    id = sprintf('%d',idx(i));
    text(stats(idx(i)).Centroid(1),stats(idx(i)).Centroid(2),id);
end

cell = 166;
pixels = CC.PixelIdxList{cell};
[r c] = ind2sub(size(orgImg), pixels);
points = [];
for i=1:length(pixels)
%       for j=1:stats(cell).MinorAxisLength*bw2(pixels(i))
%         z = ceil(j/2);
%         if (mod(j,2))
%             z = -z;
%         end
        points = [points;[r(i) c(i) i]];
%       end     
end

[B I]=unique(points,'rows');

clstr = 4;
opt = statset('MaxIter',400);
obj = gmdistribution.fit([points(:,1) points(:,2)],clstr,'Options',opt,'Replicates',15);
kIdx = cluster(obj, [points(:,1) points(:,2)]);

[kIdxK m] = kmeans([points(:,1) points(:,2)],clstr,'Replicates',15);

hulls = [];
for i=1:clstr
    hulls(i).pixels = [];
end

for i=1:length(I)
    hulls(kIdx(I(i))).pixels = [hulls(kIdx(I(i))).pixels; points(I(i),:)];
end

hullsK = [];
for i=1:clstr
    hullsK(i).pixels = [];
end

for i=1:length(I)
    hullsK(kIdxK(I(i))).pixels = [hullsK(kIdxK(I(i))).pixels; points(I(i),:)];
end

% for i=1:4
%     hulls(i).pixels = [r(kIdx==i) c(kIdx==i)];
% end

%imagesc(gry); colormap gray, hold on

plot(hulls(1).pixels(:,2),hulls(1).pixels(:,1),'.r');
plot(hulls(2).pixels(:,2),hulls(2).pixels(:,1),'.g');
plot(hulls(3).pixels(:,2),hulls(3).pixels(:,1),'.b');
plot(hulls(4).pixels(:,2),hulls(4).pixels(:,1),'.c');
plot(hulls(5).pixels(:,2),hulls(5).pixels(:,1),'om');
plot(hulls(6).pixels(:,2),hulls(6).pixels(:,1),'.y');
plot(hulls(7).pixels(:,2),hulls(7).pixels(:,1),'.k');

plot(hullsK(1).pixels(:,2),hullsK(1).pixels(:,1),'.r');
plot(hullsK(2).pixels(:,2),hullsK(2).pixels(:,1),'.g');
plot(hullsK(3).pixels(:,2),hullsK(3).pixels(:,1),'.b');
plot(hullsK(4).pixels(:,2),hullsK(4).pixels(:,1),'.c');
plot(hullsK(5).pixels(:,2),hullsK(5).pixels(:,1),'.m');
plot(hullsK(6).pixels(:,2),hullsK(6).pixels(:,1),'.y');
plot(hullsK(7).pixels(:,2),hullsK(7).pixels(:,1),'.k');

plot(m(1,2),m(1,1),'sk','MarkerFaceColor','k');
plot(m(2,2),m(2,1),'sk','MarkerFaceColor','k');
plot(m(3,2),m(3,1),'sk','MarkerFaceColor','k');
plot(m(4,2),m(4,1),'sk','MarkerFaceColor','k');
plot(m(5,2),m(5,1),'sk','MarkerFaceColor','k');
