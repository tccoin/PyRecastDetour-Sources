cid=$(docker create pyrecastdetour:py310-amd64)
docker cp "$cid:/app/dist/." ./dist
docker rm "$cid"
SITE_PACKAGES=$(python3 -c "import site; print(site.getsitepackages()[0])")
sudo cp dist/PyRecastDetour*.so $SITE_PACKAGES/
echo "Installed PyRecastDetour to $SITE_PACKAGES"
echo "Testing import"
python3 -c "import PyRecastDetour as m; print(m, 'OK')"
