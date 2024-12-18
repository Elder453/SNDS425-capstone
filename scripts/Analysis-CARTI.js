// ===========================
// Script: Analysis-CARTI.js
// Purpose: Fit and evaluate a CART (Classification and Regression Trees) classifier for land cover classification.
// ===========================

/*
  ===========================
  Documentation Overview
  ===========================
  
  This Google Earth Engine (GEE) script, `Analysis-CARTI.js`, is designed to perform 
  land cover classification using a CART classifier. The script involves data preprocessing, 
  model training, evaluation, visualization of classification results, and analysis of 
  misclassifications. Below is a comprehensive breakdown of each section of the script.
  
  **Important:** Before running this script, YOU must manually download the dataset from 
  [monthly_clean.csv](https://yaleedu-my.sharepoint.com/:x:/g/personal/elder_veliz_yale_edu/EZq38Cm-mb1KgtE1yek3qEoBWhINU2AqyQiOd9FmYThiVg?e=rnXsD5)
  //  and upload it to your GEE assets (we've provided a view access to Emmanuelle's GEE script in the report for reference). 
  // Once uploaded, ensure that it is accessible as `var dataset` within the script.
  
  ---------------------------
  Table of Contents
  ---------------------------
  1. Load Required Libraries
  2. Load and Prepare Data
     - Manual Download and Upload Instructions
     - Defining Geometries and Filtering Data
     - Encoding Landcover Classes
  3. Data Splitting
     - Training and Testing Sets
  4. Model Training
     - CART Classifier
  5. Model Evaluation
     - Classification Results
     - Confusion Matrix and Metrics
  6. Visualization
     - Styling Classified Points
     - Adding Interactive Click Events
     - Creating Legends
  7. Error Analysis
     - Identifying and Styling Misclassified Points
     - Calculating Misclassification Rates
  8. Best Practices and Recommendations
*/

// ---------------------------
// 1. Load Required Libraries
// ---------------------------

/*
  For this script, GEE's built-in functions are sufficient.
*/

// ---------------------------
// 2. Load and Prepare Data
// ---------------------------

/*
  **Manual Download and Upload Instructions:**
  
  1. **Download the Dataset:**
     - Visit [monthly_clean.csv](https://yaleedu-my.sharepoint.com/:x:/g/personal/elder_veliz_yale_edu/EZq38Cm-mb1KgtE1yek3qEoBWhINU2AqyQiOd9FmYThiVg?e=rnXsD5)
     // to download the required table.
  
  2. **Upload to GEE Assets:**
     - Open the [GEE Code Editor](https://code.earthengine.google.com/).
     - In the left panel, navigate to the "Assets" tab.
     - Click on "NEW" and select "Table upload".
     - Upload the downloaded table and name it appropriately (e.g., `monthly_clean`).
*/

var dataset = ee.FeatureCollection('users/yourusername/monthly_clean'); // Replace with YOUR dataset path

var datasetBounds = dataset.geometry();
print("Dataset Bounds:", datasetBounds);

// Define the bounds for the continental United States with a buffer
var usBounds = ee.Geometry.Rectangle([-130, 24, -65, 50]);  // Rough bounds with buffer
// Uncomment the line below to visualize the US bounds on the map
// Map.addLayer(usBounds, {color: 'blue'}, 'US Bounds');

// Define the geometry for the state
var nyBounds = usBounds

// Uncomment the line below to visualize the NY bounds on the map
//Map.addLayer(geometrydrawn.bounds(), {color: 'blue'}, 'NY Border');

var Filtereddataset = dataset.filterBounds(nyBounds)
  .filter(ee.Filter.eq('image_year', 2018))

// Ensure unique entries by `plotid` to avoid duplicates
var distinctDataset = Filtereddataset.distinct(['plotid']);

// Extract unique landcover classes and encode them
var uniqueLandcoverValues = distinctDataset.aggregate_array('dominant_landcover').distinct();
print("Unique 'dominant_landcover' Values:", uniqueLandcoverValues);

var landcoverClasses = ee.Dictionary.fromLists(
  uniqueLandcoverValues, 
  ee.List.sequence(0, uniqueLandcoverValues.length().subtract(1))
);
print("Dynamic Landcover Classes:", landcoverClasses);

var encodedDataset = distinctDataset.map(function(feature) {
  var landcoverValue = feature.get('dominant_landcover');
  var classValue = ee.Algorithms.If(
    landcoverClasses.contains(landcoverValue),
    landcoverClasses.get(landcoverValue),
    -1  // Default for missing keys
  );
  return feature.set('landcover', classValue);
});

// Print first 10 features for verification
print("First 10 Features of Encoded Dataset:", encodedDataset.limit(10));

// Check for missing landcover values
var missingLandcover = encodedDataset.filter(ee.Filter.notNull(['dominant_landcover']).not());
print("Features Missing 'landcover':", missingLandcover);

var predictors = ['NDVI', 'SR_B1', 'SR_B2', 'SR_B3', 'SR_B4', 'SR_B5', 'SR_B7', 'elevation_meters'];


// ---------------------------
// 3. Data Splitting
// ---------------------------

// Split the dataset into training and testing sets (e.g., 70-30 split)
var withRandom = encodedDataset.randomColumn('random');
var trainingSet = withRandom.filter(ee.Filter.lt('random', 0.7));
var testingSet = withRandom.filter(ee.Filter.gte('random', 0.7));
var totalPerClass = trainingSet.aggregate_histogram('dominant_landcover');
print('Total Points per Class:', totalPerClass);

print("Unique landcover classes in testingSet:", testingSet.aggregate_array('landcover').distinct());


// ---------------------------
// 4. Model Training
// ---------------------------

// Train the CART classifier using pre-computed predictors
var classifier = ee.Classifier.smileCart().train({
  features: trainingSet,
  classProperty: 'landcover',
  inputProperties: predictors
});
print("Classifier Trained");


// ---------------------------
// 5. Model Evaluation
// ---------------------------

// Classify the entire dataset (or a subset) for evaluation
var classified = testingSet.classify(classifier);
print("Classified Testing Set:", classified.limit(10));


// ---------------------------
// 6. Visualization
// ---------------------------

// function to conditionally set properties of feature collection
var setPointProperties = function(f){ 
  var klass = f.get("landcover") // 0 or 1
  var mapDisplayColors = ee.List( ['mediumblue', 'deepskyblue', 'springgreen','mediumslateblue', 'mediumseagreen', 'darkcyan', 'lightcyan']); // class 0 should be blue, class 1 should be red
  
  // use the class as index to lookup the corresponding display color
  return f.set({style: {pointSize:6, color: mapDisplayColors.get(klass), width:0.5}})
}

// apply the function and view the results on map
var styled = classified.map(setPointProperties)

Map.addLayer(styled.style({styleProperty: "style"}), {}, 'conditionally styled')


// ---------------------------
// 7. Interactive Click Events
// ---------------------------

// Define a click event to display feature properties
Map.onClick(function(coords) {
  var clickedPoint = ee.Geometry.Point([coords.lon, coords.lat]);
  var buffer = clickedPoint.buffer(9000);
  var nearestFeature = styled.filterBounds(buffer).first();

  nearestFeature.evaluate(function(feature) {
    if (feature) {
      print('Clicked Point Properties:', feature.properties);

      // Highlight the clicked point
      Map.addLayer(buffer, {color: 'white', pointSize: 6}, 'Clicked Point');
    } else {
      print('No feature found near the clicked location.');
    }
  });
});


// ---------------------------
// 8. Adding Legends
// ---------------------------

// Define a landcover-to-color palette and class names
var landcoverClasses = ['Water', 'Grass/forb/herb', 'Trees', 'Shrubs', 'Barren', 'Impervious', 'Snow/ice'];
var landcoverPalette = ['mediumblue', 'deepskyblue', 'springgreen','mediumslateblue', 'mediumseagreen', 'darkcyan', 'lightcyan'];

// Create a panel for the legend
var legend = ui.Panel({
  style: {
    position: 'bottom-left',
    padding: '8px 15px'
  }
});

// Add a title to the legend
var legendTitle = ui.Label({
  value: 'True Landcover Legend',
  style: {
    fontWeight: 'bold',
    fontSize: '16px',
    margin: '0 0 4px 0',
    padding: '0'
  }
});
legend.add(legendTitle);

// Create color boxes and labels for each class
for (var i = 0; i < landcoverClasses.length; i++) {
  var colorBox = ui.Label({
    style: {
      backgroundColor: landcoverPalette[i],
      padding: '8px',
      margin: '0 8px 0 0',
      border: '1px solid black'
    }
  });
  
  var description = ui.Label({
    value: landcoverClasses[i],
    style: {margin: '0', fontSize: '12px'}
  });
  
  // Add the color and label to the legend
  var legendRow = ui.Panel({
    widgets: [colorBox, description],
    layout: ui.Panel.Layout.Flow('horizontal')
  });
  legend.add(legendRow);
}
Map.add(legend);


// ---------------------------
// 9. Error Analysis
// ---------------------------

var misclassifiedPointsWithDescriptions = classified.map(function(feature) {
  var actual = feature.get('landcover');          // Actual class
  var predicted = feature.get('classification'); // Predicted class
  var error = ee.Number(actual).neq(predicted); 
  return feature.set('error', error);
});

var misclassifiedPoints = misclassifiedPointsWithDescriptions.filter(ee.Filter.eq('error', 1));
print('Misclassified Points:', misclassifiedPoints.limit(10));
// Style misclassified points

var misclassifiedPointsWithDescriptions = misclassifiedPoints.map(function(feature) {
  var actual = feature.get('landcover');          // True class
  var predicted = feature.get('classification'); // Predicted class
  var description = ee.String(actual).cat(' -> ').cat(ee.String(predicted)); // Combine for description
  return feature.set('misclassificationType', description);
});
print('Misclassified points w desriptions', misclassifiedPointsWithDescriptions.limit(10))

var MisclassificationTypes = misclassifiedPointsWithDescriptions
  .aggregate_histogram('misclassificationType');
print('Misclassification Types:', MisclassificationTypes);

var transitionType1 = '2.0 -> 1'; // Replace with the actual transition type
var transitionType2 = '1.0 -> 2';
var transitionType3 = '2.0 -> 3';
var transitionType4 = '3.0 -> 2';
var transitionType5 = '2.0 -> 4';
var transitionType6 = '4.0 -> 2';

var spectype1 = misclassifiedPointsWithDescriptions.filter(
  ee.Filter.eq('misclassificationType', transitionType1)
);
var spectype2 = misclassifiedPointsWithDescriptions.filter(
  ee.Filter.eq('misclassificationType', transitionType2)
);
var spectype3 = misclassifiedPointsWithDescriptions.filter(
  ee.Filter.eq('misclassificationType', transitionType3)
);
var spectype4 = misclassifiedPointsWithDescriptions.filter(
  ee.Filter.eq('misclassificationType', transitionType4)
);
var spectype5 = misclassifiedPointsWithDescriptions.filter(
  ee.Filter.eq('misclassificationType', transitionType5)
);
var spectype6 = misclassifiedPointsWithDescriptions.filter(
  ee.Filter.eq('misclassificationType', transitionType6)
);

var spectype = spectype1.merge(spectype2).merge(spectype3).merge(spectype4).merge(spectype5).merge(spectype6)

var uniqueerrors = spectype.aggregate_array('misclassificationType').distinct();
print('unique errors', uniqueerrors);

var errorClasses = ee.Dictionary.fromLists(
  uniqueerrors, 
  ee.List.sequence(0, uniqueerrors.length().subtract(1))
);
print("Dynamic Error Classes:", errorClasses);


var encodederror = spectype.map(function(feature) {
  var errorValue = feature.get('misclassificationType');
  var classValue = ee.Algorithms.If(
    errorClasses.contains(errorValue),
    errorClasses.get(errorValue),
    -1  // Default for missing keys
  );
  return feature.set('misclass type', classValue);
});
print('encoded error dataset', encodederror.limit(10));

var errorClasses = ['Grass as Trees', 'Trees as Grass', 'Trees as Shrubs', 'Shrubs as Trees', 'Trees as Barren', 'Barren as Trees'];
var errorPalette = ['crimson', 'darkorange','peachpuff', 'gold','yellow', 'deeppink', 'lightcyan']
var setErrorProperties = function(f){ 
  var klass = f.get('misclass type') 
  var mapDisplayColors = ee.List(errorPalette); 
  // use the class as index to lookup the corresponding display color
  return f.set({style: {color: mapDisplayColors.get(klass)}})
}

var errorstyled = encodederror.map(setErrorProperties)
Map.addLayer(errorstyled.style({styleProperty: "style"}), {}, 'Misclassification Types')

// Create a panel for the legend
var legend = ui.Panel({
  style: {
    position: 'bottom-left',
    padding: '8px 15px'
  }
});
// Add a title to the legend
var legendTitle = ui.Label({
  value: 'Misclassifications Legend',
  style: {
    fontWeight: 'bold',
    fontSize: '16px',
    margin: '0 0 4px 0',
    padding: '0'
  }
});
legend.add(legendTitle);
// Create color boxes and labels for each class
for (var i = 0; i < errorClasses.length; i++) {
  var colorBox = ui.Label({
    style: {
      backgroundColor: errorPalette[i],
      padding: '8px',
      margin: '0 8px 0 0',
      border: '1px solid black'
    }
  });
  
  var description = ui.Label({
    value: errorClasses[i],
    style: {margin: '0', fontSize: '12px'}
  });
  
  // Add the color and label to the legend
  var legendRow = ui.Panel({
    widgets: [colorBox, description],
    layout: ui.Panel.Layout.Flow('horizontal')
  });
  legend.add(legendRow);
}
Map.add(legend);


// ---------------------------
// 10. Evaluating Model Performance
// ---------------------------

var confusionMatrix = classified.errorMatrix('landcover', 'classification');
print('Confusion Matrix:', confusionMatrix);
print('Overall Accuracy:', confusionMatrix.accuracy());
print('Kappa Coefficient:', confusionMatrix.kappa());


// Derive metrics for each class
var classMetrics = confusionMatrix.producersAccuracy(); // Recall for each class
print('Class Recall (Producers Accuracy):', classMetrics);

var userMetrics = confusionMatrix.consumersAccuracy(); // Precision for each class
print('Class Precision (Consumers Accuracy):', userMetrics);

var misclassifiedByClass = misclassifiedPoints.aggregate_histogram('landcover');
print('Misclassified Points by Class:', misclassifiedByClass);

var totalPerClass = classified.aggregate_histogram('landcover');
print('Total Points per Class:', totalPerClass);

var totalDict = ee.Dictionary(totalPerClass);
var misclassifiedDict = ee.Dictionary(misclassifiedByClass);

// Compute misclassification rates
var misclassificationRates = misclassifiedDict.map(function(key, value) {
  var total = ee.Number(totalDict.get(key));
  return ee.Number(value).divide(total);  // Misclassified points / Total points
});
print('Misclassification Rates by Class:', misclassificationRates);

print('Size of distinctDataset:', distinctDataset.size());
print('Size of trainingSet:', trainingSet.size());
print('Size of testingSet:', testingSet.size());
print('Size of Misclass:', misclassifiedPointsWithDescriptions.size());
print('Size of Misclass Types:', MisclassificationTypes.size());
