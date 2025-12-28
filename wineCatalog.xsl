<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:param name="mapsApiKey" />

    <xsl:output method="html" encoding="UTF-8" indent="yes"/>

    <xsl:key name="regionLookup" match="region" use="@regionId"/>
    <xsl:key name="wineryLookup" match="winery" use="@wineryId"/>

    <xsl:template match="/">
        <html>
            <head>
                <title>Каталог на Български Вина</title>
                <script src="https://d3js.org/d3.v7.min.js"></script>
                
                <style>
                    body { font-family: 'Segoe UI', sans-serif; background: #f9f9f9; padding: 20px; color: #333; }
                    h1 { text-align: center; color: #722f37; border-bottom: 3px solid #722f37; padding-bottom: 15px; }
                    
                    /* --- CONTROLS --- */
                    .control-panel { 
                        background: white; padding: 15px; margin-bottom: 20px; border-radius: 8px; 
                        box-shadow: 0 2px 5px rgba(0,0,0,0.1); display: flex; flex-wrap: wrap; gap: 15px; justify-content: space-between; align-items: center;
                    }
                    .btn-group button { 
                        padding: 8px 12px; margin-right: 5px; cursor: pointer; border: 1px solid #722f37; 
                        background: white; color: #722f37; border-radius: 4px; font-weight: bold;
                    }
                    .btn-group button:hover, .btn-group button.active { background: #722f37; color: white; }
                    
                    .filters { display: flex; gap: 10px; align-items: center; }
                    .filters select { padding: 6px; border: 1px solid #ccc; border-radius: 4px; }
                    
                    /* --- GRID --- */
                    .catalog-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(230px, 1fr)); gap: 20px; }
                    
                    /* --- CARDS --- */
                    .wine-card { 
                        background: white; border-radius: 8px; overflow: hidden; 
                        box-shadow: 0 2px 5px rgba(0,0,0,0.1); cursor: pointer; transition: transform 0.2s;
                        display: flex; flex-direction: column; text-align: center; padding-bottom: 10px;
                    }
                    .wine-card:hover { transform: translateY(-5px); box-shadow: 0 5px 15px rgba(0,0,0,0.2); }
                    .card-image { width: 100%; height: 180px; object-fit: contain; background: #f0f0f0; padding: 10px; box-sizing: border-box; }
                    .card-name { padding: 10px; font-weight: bold; color: #2c3e50; min-height: 40px; display: flex; align-items: center; justify-content: center; }
                    .card-price { margin-top: auto; color: #722f37; font-weight: bold; font-size: 1.1em; }
                    
                    /* --- SECTIONS --- */
                    .view-section { display: none; }
                    #view-all { display: block; } /* Default visible */
                    h2.group-title { width: 100%; color: #722f37; border-left: 5px solid #722f37; padding-left: 10px; margin-top: 30px; }

                    /* --- GOOGLE MAP --- */
                    #map-container { 
                        width: 100%; height: 500px; background: #e0f7fa; border-radius: 8px; 
                        overflow: hidden; 
                    }

                    /* --- DETAILS PAGE --- */
                    .wine-page { display: none; background: white; max-width: 900px; margin: 0 auto; padding: 30px; border-radius: 8px; box-shadow: 0 0 20px rgba(0,0,0,0.2); }
                    .back-btn { background: #722f37; color: white; border: none; padding: 10px 20px; border-radius: 4px; cursor: pointer; margin-bottom: 20px; }
                    .page-content { display: flex; gap: 30px; flex-wrap: wrap; }
                    .page-image img { max-width: 300px; width: 100%; border-radius: 8px; }
                    .page-info { flex: 1; }
                    .info-table { width: 100%; border-collapse: collapse; margin-top: 15px; }
                    .info-table td { padding: 8px 0; border-bottom: 1px solid #eee; }
                    .label { font-weight: bold; width: 120px; }
                    
                    /* --- D3 RATING --- */
                    .rating-viz-container { display: flex; align-items: center; height: 30px; }
                    .rating-viz-container svg { overflow: visible; }
                    
                    /* --- REVIEWS --- */
                    .reviews-section { margin-top: 30px; padding-top: 20px; border-top: 1px solid #eee; }
                    .review-container { margin-top: 15px; padding: 10px; background: #fff9c4; border-left: 4px solid #ff9800; display: none; }
                    .review-item { padding-bottom: 10px; margin-bottom: 10px; border-bottom: 1px solid #ddd; }
                    .review-stars { float: right; color: #ff9800; }
                </style>
                
                <script>
                <![CDATA[
                    (function(g){var h,a,k,p="The Google Maps JavaScript API",c="google",l="importLibrary",q="__ib__",m=document,b=window;b=b[c]||(b[c]={});var d=b.maps||(b.maps={}),r=new Set,e=new URLSearchParams,u=()=>h||(h=new Promise(async(f,n)=>{await (a=m.createElement("script"));e.set("libraries",[...r]+"");for(k in g)e.set(k.replace(/[A-Z]/g,t=>"_"+t[0].toLowerCase()),g[k]);e.set("callback",c+".maps."+q);a.src=`https://maps.googleapis.com/maps/api/js?`+e;d[q]=f;a.onerror=()=>h=n(Error(p+" could not load."));a.nonce=m.querySelector("script[nonce]")?.nonce||"";m.head.append(a)}));d[l]?console.warn(p+" only loads once. Ignoring:",g):d[l]=(f,...n)=>r.add(f)&&u().then(()=>d[l](f,...n))})({
                        key: "API_KEY",
                        v: "weekly"
                    });
                ]]>
                </script>

                <script type="text/javascript">
                <![CDATA[
                    // --- DATA PREPARATION ---
                    // Hardcoded Coordinates for Wineries (approximate locations in Bulgaria)
                    const wineryCoordinates = {
                        'winery1': { lat: 43.40, lng: 24.60 }, // Riverine Hills (North)
                        'winery2': { lat: 42.14, lng: 24.75 }, // Dragomir (Plovdiv)
                        'winery3': { lat: 43.60, lng: 25.50 }, // Maxxima (North)
                        'winery4': { lat: 43.72, lng: 22.58 }, // Magura (Rabisha)
                        'winery5': { lat: 43.20, lng: 27.00 }, // Tsarev Brod (Shumen)
                        'winery6': { lat: 41.88, lng: 26.10 }, // Bassarea (Sakar)
                        'winery7': { lat: 41.52, lng: 23.39 }, // Villa Melnik (Melnik)
                        'winery8': { lat: 42.20, lng: 24.50 }, // Via Verde (Pazardzhik area)
                        'winery9': { lat: 42.50, lng: 24.55 }  // Starosel
                    };

                    // Generated List of Wines from XML
                    const wineList = [
                ]]>
                    <xsl:for-each select="wineCatalog/wines/wine">
                        {
                            id: "<xsl:value-of select="@wineId"/>",
                            name: "<xsl:value-of select="name"/>",
                            wineryId: "<xsl:value-of select="@wineryIdRef"/>",
                            price: "<xsl:value-of select="price"/>",
                            rating: "<xsl:value-of select="substring-before(rating, '/')"/>"
                        }<xsl:if test="position() != last()">,</xsl:if>
                    </xsl:for-each>
                <![CDATA[
                    ];

                    // --- GOOGLE MAP LOGIC ---
                    let map;
                    let markers = [];

                    async function initMap() {
                        const { Map } = await google.maps.importLibrary("maps");
                        const { AdvancedMarkerElement } = await google.maps.importLibrary("marker");

                        map = new Map(document.getElementById("map-container"), {
                            center: { lat: 42.7339, lng: 25.4858 }, // Center of Bulgaria
                            zoom: 7,
                            mapId: "DEMO_MAP_ID" // Required for AdvancedMarkerElement
                        });

                        const infoWindow = new google.maps.InfoWindow();

                        // Add markers for each wine
                        wineList.forEach((wine, index) => {
                            const coords = wineryCoordinates[wine.wineryId];
                            if(coords) {
                                // Add a tiny random offset so wines from the same winery don't perfectly overlap
                                const offsetLat = coords.lat + (Math.random() - 0.5) * 0.05; 
                                const offsetLng = coords.lng + (Math.random() - 0.5) * 0.05;

                                const marker = new AdvancedMarkerElement({
                                    map: map,
                                    position: { lat: offsetLat, lng: offsetLng },
                                    title: wine.name
                                });

                                marker.addListener("click", () => {
                                    infoWindow.setContent(`
                                        <div style="padding:5px; color:#333;">
                                            <h3 style="margin:0 0 5px 0;">${wine.name}</h3>
                                            <p><strong>Price:</strong> ${wine.price} BGN</p>
                                            <button onclick="openWinePage('${wine.id}')" style="margin-top:5px; cursor:pointer;">See Details</button>
                                        </div>
                                    `);
                                    infoWindow.open(map, marker);
                                });
                                markers.push(marker);
                            }
                        });
                    }

                    // --- D3 RATING LOGIC ---
                    function renderD3Rating(wineId, ratingStr) {
                        const containerId = "#rating-viz-" + wineId;
                        const container = d3.select(containerId);
                        
                        // Clear previous svg if exists
                        container.selectAll("*").remove();

                        // Parse rating (e.g., "3/5" -> 3)
                        let score = 0;
                        if(ratingStr && ratingStr.includes('/')) {
                            score = parseInt(ratingStr.split('/')[0]);
                        } else if (ratingStr) {
                            score = parseInt(ratingStr);
                        }

                        if(isNaN(score)) {
                            container.append("span").text("N/A");
                            return;
                        }

                        const width = 120;
                        const height = 24;
                        const svg = container.append("svg")
                            .attr("width", width)
                            .attr("height", height);

                        // Draw 5 circles
                        const data = [1, 2, 3, 4, 5];
                        
                        svg.selectAll("circle")
                            .data(data)
                            .enter()
                            .append("circle")
                            .attr("cx", (d, i) => 12 + i * 24)
                            .attr("cy", 12)
                            .attr("r", 8)
                            .style("fill", d => d <= score ? "#ffc107" : "#e0e0e0") // Gold for active, Grey for inactive
                            .style("stroke", "#d4a000")
                            .style("stroke-width", "1px");
                    }

                    // --- VIEW MANAGEMENT ---
                    var isMapInitialized = false;

                    function switchView(viewId) {
                        var sections = document.querySelectorAll('.view-section');
                        for(var i=0; i<sections.length; i++) sections[i].style.display = 'none';
                        
                        var pages = document.querySelectorAll('.wine-page');
                        for(var i=0; i<pages.length; i++) pages[i].style.display = 'none';

                        document.getElementById('control-panel').style.display = 'flex';
                        document.getElementById(viewId).style.display = 'block';
                        
                        var filters = document.getElementById('filter-controls');
                        
                        if(viewId === 'view-all') {
                            filters.style.visibility = 'visible';
                            // FIX: Reset Grid Filters
                            var grid = document.getElementById('grid-all');
                            var cards = grid.getElementsByClassName('wine-card');
                            for(var i=0; i<cards.length; i++) {
                                cards[i].style.display = 'flex';
                            }
                            document.getElementById('filterType').value = "";
                            document.getElementById('filterVintage').value = "";
                        } else {
                            filters.style.visibility = 'hidden';
                        }

                        if(viewId === 'view-map' && !isMapInitialized) {
                            initMap();
                            isMapInitialized = true;
                        }
                    }

                    function openWinePage(id) {
                        document.getElementById('control-panel').style.display = 'none';
                        var sections = document.querySelectorAll('.view-section');
                        for(var i=0; i<sections.length; i++) sections[i].style.display = 'none';
                        
                        document.getElementById('page-' + id).style.display = 'block';
                        window.scrollTo(0,0);

                        // Trigger D3 Rating Render
                        var ratingDiv = document.getElementById('rating-viz-' + id);
                        var ratingVal = ratingDiv.getAttribute('data-rating');
                        renderD3Rating(id, ratingVal);
                    }

                    function backToCatalog(id) {
                        document.getElementById('page-' + id).style.display = 'none';
                        document.getElementById('control-panel').style.display = 'flex';
                        switchView('view-all'); 
                    }

                    function sortByPrice(order) {
                        if(!order) return;
                        var grid = document.getElementById('grid-all');
                        var cards = Array.from(grid.getElementsByClassName('wine-card'));

                        cards.sort(function(a, b) {
                            var p1 = parseFloat(a.getAttribute('data-price'));
                            var p2 = parseFloat(b.getAttribute('data-price'));
                            return order === 'asc' ? p1 - p2 : p2 - p1;
                        });
                        for(var i=0; i<cards.length; i++) grid.appendChild(cards[i]);
                    }

                    function applyFilters() {
                        var typeVal = document.getElementById('filterType').value;
                        var vintageVal = document.getElementById('filterVintage').value;
                        
                        var grid = document.getElementById('grid-all');
                        var cards = grid.getElementsByClassName('wine-card');
                        for(var i=0; i<cards.length; i++) {
                            var card = cards[i];
                            var cType = card.getAttribute('data-type');
                            var cVintage = card.getAttribute('data-vintage');
                            
                            var matchType = (typeVal === "" || cType === typeVal);
                            var matchVintage = (vintageVal === "" || cVintage === vintageVal);
                            if(matchType && matchVintage) {
                                card.style.display = 'flex';
                            } else {
                                card.style.display = 'none';
                            }
                        }
                    }

                    async function loadReviews(btn, wineId) {
                        var container = btn.nextElementSibling;
                        if(container.getAttribute('data-loaded') === 'true') {
                            container.style.display = (container.style.display === 'block') ? 'none' : 'block';
                            btn.innerText = (container.style.display === 'block') ? 'Скрий мнения' : 'Виж мнения';
                            return;
                        }
                        btn.innerText = 'Зареждане...';
                        try {
                            const response = await fetch('reviews.xml');
                            if(!response.ok) throw new Error("Connection failed");
                            const text = await response.text();
                            const parser = new DOMParser();
                            const doc = parser.parseFromString(text, "text/xml");
                            let html = '';
                            let found = false;
                            let reviews = doc.querySelectorAll('review');
                            reviews.forEach(function(r) {
                                if(r.getAttribute('wineId') === wineId) {
                                    found = true;
                                    let rating = r.getAttribute('rating');
                                    let stars = '';
                                    for(let k=0; k<rating; k++) stars += '★';
                                    for(let k=rating; k<5; k++) stars += '☆';
                                    let user = r.querySelector('user').textContent;
                                    let comment = r.querySelector('comment').textContent;
                                    html += '<div class="review-item"><span style="font-weight:bold">' + user + '</span>' +
                                            '<span class="review-stars">' + stars + '</span><br/>' +
                                            '<i>"' + comment + '"</i></div>';
                                }
                            });
                            container.innerHTML = found ? html : '<i>Няма мнения.</i>';
                            container.style.display = 'block';
                            container.setAttribute('data-loaded', 'true');
                            btn.innerText = 'Скрий мнения';
                        } catch(e) {
                            console.error(e);
                            btn.innerText = 'Грешка при зареждане';
                        }
                    }
                ]]>
                </script>
            </head>
            <body>
                <h1>Каталог на Български Вина</h1>

                <div id="control-panel" class="control-panel">
                    <div class="btn-group">
                        <button onclick="switchView('view-all')">Всички</button>
                        <button onclick="switchView('view-regions')">Списък Региони</button>
                        <button onclick="switchView('view-wineries')">Списък Изби</button>
                        <button onclick="switchView('view-map')">🗺️ Карта</button>
                    </div>

                    <div id="filter-controls" class="filters">
                        <label>Цена:</label>
                        <select onchange="sortByPrice(this.value)">
                            <option value="">—</option>
                            <option value="asc">Възходящо</option>
                            <option value="desc">Низходящо</option>
                        </select>

                        <label>Тип:</label>
                        <select id="filterType" onchange="applyFilters()">
                            <option value="">Всички</option>
                            <xsl:for-each select="wineCatalog/wines/wine[not(type=preceding::type)]">
                                <option value="{type}"><xsl:value-of select="type"/></option>
                            </xsl:for-each>
                        </select>

                        <label>Реколта:</label>
                        <select id="filterVintage" onchange="applyFilters()">
                            <option value="">Всички</option>
                            <xsl:for-each select="wineCatalog/wines/wine[not(vintage=preceding::vintage)]">
                                <xsl:sort select="vintage" data-type="number"/>
                                <option value="{vintage}"><xsl:value-of select="vintage"/></option>
                            </xsl:for-each>
                        </select>
                    </div>
                </div>

                <div id="view-all" class="view-section">
                    <div id="grid-all" class="catalog-grid">
                        <xsl:call-template name="renderCards">
                            <xsl:with-param name="items" select="wineCatalog/wines/wine"/>
                        </xsl:call-template>
                    </div>
                </div>

                <div id="view-regions" class="view-section">
                    <xsl:for-each select="wineCatalog/regions/region">
                        <h2 class="group-title"><xsl:value-of select="name"/></h2>
                        <div class="catalog-grid">
                            <xsl:variable name="rid" select="@regionId"/>
                            <xsl:call-template name="renderCards">
                                <xsl:with-param name="items" select="/wineCatalog/wines/wine[@regionIdRef=$rid]"/>
                            </xsl:call-template>
                        </div>
                    </xsl:for-each>
                </div>

                <div id="view-wineries" class="view-section">
                    <xsl:for-each select="wineCatalog/wineries/winery">
                        <h2 class="group-title"><xsl:value-of select="name"/></h2>
                        <div class="catalog-grid">
                            <xsl:variable name="wid" select="@wineryId"/>
                            <xsl:call-template name="renderCards">
                                <xsl:with-param name="items" select="/wineCatalog/wines/wine[@wineryIdRef=$wid]"/>
                            </xsl:call-template>
                        </div>
                    </xsl:for-each>
                </div>
                
                <div id="view-map" class="view-section">
                    <h2 class="group-title" style="text-align:center; border:none;">Локации на Вината (по Изби)</h2>
                    <div id="map-container"></div>
                </div>

                <xsl:for-each select="wineCatalog/wines/wine">
                    <div id="page-{@wineId}" class="wine-page">
                        <button class="back-btn" onclick="backToCatalog('{@wineId}')">← Обратно</button>
                        <div class="page-content">
                            <div class="page-image">
                                <img src="{unparsed-entity-uri(image/@source)}" />
                            </div>
                            <div class="page-info">
                                <h2 style="color:#722f37; margin-top:0;"><xsl:value-of select="name"/></h2>
                                <table class="info-table">
                                    <tr><td class="label">Цена:</td><td style="color:#722f37; font-weight:bold;"><xsl:value-of select="price"/> <xsl:value-of select="price/@currency"/></td></tr>
                                    <tr><td class="label">Тип:</td><td><xsl:value-of select="type"/></td></tr>
                                    <tr><td class="label">Реколта:</td><td><xsl:value-of select="vintage"/></td></tr>
                                    <tr><td class="label">Изба:</td><td><xsl:value-of select="key('wineryLookup', @wineryIdRef)/name"/></td></tr>
                                    <tr><td class="label">Регион:</td><td><xsl:value-of select="key('regionLookup', @regionIdRef)/name"/></td></tr>
                                    <tr>
                                        <td class="label">Рейтинг:</td>
                                        <td>
                                            <div id="rating-viz-{@wineId}" class="rating-viz-container" data-rating="{rating}"></div>
                                        </td>
                                    </tr>
                                </table>
                                <div style="margin-top:20px; font-style:italic; border-left:4px solid #ff9800; padding:10px; background:#fdfdfd;">
                                    <xsl:value-of select="sommelierDescription"/>
                                </div>
                                <div class="reviews-section">
                                    <h3>Мнения</h3>
                                    <button onclick="loadReviews(this, '{@wineId}')" style="cursor:pointer; padding:6px 12px;">Виж мнения</button>
                                    <div class="review-container"></div>
                                </div>
                            </div>
                        </div>
                    </div>
                </xsl:for-each>
            </body>
        </html>
    </xsl:template>

    <xsl:template name="renderCards">
        <xsl:param name="items"/>
        <xsl:for-each select="$items">
            <div class="wine-card" 
                 onclick="openWinePage('{@wineId}')" 
                 data-price="{price}" 
                 data-type="{type}" 
                 data-vintage="{vintage}"
                 data-region="{@regionIdRef}">
                <img class="card-image" src="{unparsed-entity-uri(image/@source)}" alt="{name}"/>
                <div class="card-name"><xsl:value-of select="name"/></div>
                <div class="card-price">
                    <xsl:value-of select="price"/> <xsl:value-of select="price/@currency"/>
                </div>
            </div>
        </xsl:for-each>
    </xsl:template>

</xsl:stylesheet>