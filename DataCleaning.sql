/*

	Queries for Data Cleaning

*/
-- View the Top 1000 data
SELECT TOP 1000 *
FROM PortfolioProject..NashvilleHousing

----------------------------------------------------------------------------------------------
-- 1. Standardize Date Format
SELECT SaleDate, Convert(date, SaleDate) AS Required_Date 
FROM PortfolioProject..NashvilleHousing;

--UPDATE PortfolioProject..NashvilleHousing 
--SET SaleDate = Convert(date, SaleDate);		-- This will only work sometimes

--- This is a more reliable method to change the Datatype
ALTER TABLE PortfolioProject..NashvilleHousing 
ALTER COLUMN SaleDate date;

----------------------------------------------------------------------------------------------
-- 2. Populate Property Address Data
--SELECT *
--FROM PortfolioProject..NashvilleHousing
--WHERE PropertyAddress IS NULL;						-- Checking where the Property address is NULL

--SELECT *
--FROM PortfolioProject..NashvilleHousing
--ORDER BY PARCELID		

--> Here we can check and then create a logic that if the Address is precent in the data for the same ParcelID then we can populate the missing value with that.
SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress, b.PropertyAddress) AS RequiredPropertyAddress
FROM PortfolioProject..NashvilleHousing a
JOIN PortfolioProject..NashvilleHousing b
	ON	a.ParcelID = b.ParcelID 
	AND a.UniqueID != b.UniqueID
WHERE a.PropertyAddress IS NULL				
	
	/*
		Here we have built the logic that by self joining we need those where the ParcelID is same for both the tables, but  the Unique ID will be different.
		Now we have the Address necessary. So to populate the NULL values, we will use the above JOIN statement on an UPDATE Clause.
	*/

UPDATE a
SET a.PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM PortfolioProject..NashvilleHousing a
JOIN PortfolioProject..NashvilleHousing b
	ON	a.ParcelID = b.ParcelID 
	AND a.UniqueID != b.UniqueID
WHERE a.PropertyAddress IS NULL


SELECT *
FROM PortfolioProject..NashvilleHousing	
----------------------------------------------------------------------------------------------
-- 3. Breaking out Property Address into Individual Columns (Address, City, State)
--SELECT PropertyAddress
--FROM PortfolioProject..NashvilleHousing

--> Here we have splitted our string using Substring.
SELECT PropertyAddress, SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1) AS Address, 
SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress)+1, LEN(PropertyAddress)) AS City
FROM PortfolioProject..NashvilleHousing

--> Adding the Splitted Address values
ALTER TABLE PortfolioProject..NashvilleHousing
ADD PropertySplitAddress NVARCHAR(255);
UPDATE PortfolioProject..NashvilleHousing
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1);

ALTER TABLE PortfolioProject..NashvilleHousing
ADD PropertySplitCity NVARCHAR(255);
UPDATE PortfolioProject..NashvilleHousing
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress)+1, LEN(PropertyAddress));

SELECT PropertyAddress, PropertySplitAddress, PropertySplitCity
FROM PortfolioProject..NashvilleHousing

----------------------------------------------------------------------------------------------
-- 4. Breaking out Owner Address into Individual Columns (Address, City, State) {We will use PARSE NAME}
--SELECT OwnerAddress 
--FROM PortfolioProject..NashvilleHousing


/* 
	When Using PARSENAME it checks for periods(.) in our strings and then splits the data. So any other delimiter we need to remove.
	Also it gives the results from the back -(1 is for the last splitted string and so on)
*/
SELECT OwnerAddress, PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1) AS State, PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2) AS City ,
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3) AS Address
FROM PortfolioProject..NashvilleHousing


--> Adding the Splitted Address values
ALTER TABLE PortfolioProject..NashvilleHousing
ADD OwnerSplitAddress NVARCHAR(255);
UPDATE PortfolioProject..NashvilleHousing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3);

ALTER TABLE PortfolioProject..NashvilleHousing
ADD OwnerSplitCity NVARCHAR(255);
UPDATE PortfolioProject..NashvilleHousing
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2);

ALTER TABLE PortfolioProject..NashvilleHousing
ADD OwnerSplitState NVARCHAR(255);
UPDATE PortfolioProject..NashvilleHousing
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1);


SELECT OwnerAddress, OwnerSplitAddress, OwnerSplitCity, OwnerSplitState
FROM PortfolioProject..NashvilleHousing

----------------------------------------------------------------------------------------------
-- 5. Change Y and N to 'Yes' and 'No' in "Sold as vacant" Field
--SELECT DISTINCT(Soldasvacant)
--FROM PortfolioProject..NashvilleHousing;

--SELECT DISTINCT(Soldasvacant), COUNT(Soldasvacant)
--FROM PortfolioProject..NashvilleHousing
--GROUP BY Soldasvacant
--ORDER BY 2 DESC;

--> From the above we can see the Unique values and their counts, now we Write Case Statements
SELECT Soldasvacant, 
CASE
	WHEN Soldasvacant = 'Y' THEN 'Yes'
	WHEN Soldasvacant = 'N' THEN 'No'
	ELSE Soldasvacant
	END
FROM PortfolioProject..NashvilleHousing

--> Update the values
UPDATE PortfolioProject..NashvilleHousing
SET Soldasvacant = CASE
					WHEN Soldasvacant = 'Y' THEN 'Yes'
					WHEN Soldasvacant = 'N' THEN 'No'
					ELSE Soldasvacant
					END


SELECT DISTINCT(Soldasvacant), COUNT(Soldasvacant)
FROM PortfolioProject..NashvilleHousing
GROUP BY Soldasvacant
ORDER BY 2 DESC;

----------------------------------------------------------------------------------------------
-- 6. Remove Duplicates (Use CTE)
--SELECT *
--FROM PortfolioProject..NashvilleHousing

WITH RowNumCTE AS(
SELECT *, 
ROW_NUMBER() OVER (
	PARTITION BY ParcelID, PropertyAddress,
				 LegalReference, SaleDate, SalePrice
	ORDER BY UniqueID
)row_num
FROM PortfolioProject..NashvilleHousing
--ORDER BY ParcelID
)
DELETE
FROM RowNumCTE
WHERE row_num > 1;

--->Cross Check by running the below query
WITH RowNumCTE AS(
SELECT *, 
ROW_NUMBER() OVER (
	PARTITION BY ParcelID, PropertyAddress,
				 LegalReference, SaleDate, SalePrice
	ORDER BY UniqueID
)row_num
FROM PortfolioProject..NashvilleHousing
--ORDER BY ParcelID
)
SELECT *
FROM RowNumCTE
WHERE row_num > 1
ORDER BY UniqueID;

--> FOR REUSABILITY WE CAN CREATE A DUPLICATE TABLE -- SELECT * INTO NEW_TABLE FROM ORIGINAL_TABLE

----------------------------------------------------------------------------------------------
-- 7. Delete Unused Columns
ALTER TABLE PortfolioProject..NashvilleHousing
DROP COLUMN PropertyAddress, OwnerAddress, TaxDistrict, SaleDate

SELECT * FROM PortfolioProject..NashvilleHousing