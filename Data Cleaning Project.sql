/* 
Cleaning Data in SQL Queries

*/

SELECT * 
FROM Portfolio_Project..Nashville_Housing
;

-- Standardizing Date Format

SELECT SaleDateConverted
FROM Portfolio_Project..Nashville_Housing
;

ALTER TABLE Nashville_Housing
ADD SaleDateConverted Date
;

UPDATE Nashville_Housing
SET SaleDateConverted = CONVERT(Date,SaleDate)
;

--------------------------------------------------------------------------------------------------------------------------------

-- Populate Property Address data

SELECT *
FROM Portfolio_Project..Nashville_Housing
--WHERE PropertyAddress IS NULL
ORDER BY ParcelID
;

SELECT A.ParcelID, A.PropertyAddress, B.ParcelID, B.PropertyAddress, ISNULL(A.PropertyAddress, B.PropertyAddress)
FROM Portfolio_Project..Nashville_Housing AS A
JOIN Portfolio_Project..Nashville_Housing AS B
ON A.ParcelID = B.ParcelID
AND A.[UniqueID ] != B.[UniqueID ]
WHERE A.PropertyAddress IS NULL
;

UPDATE A
SET PropertyAddress = ISNULL(A.PropertyAddress, B.PropertyAddress)
FROM Portfolio_Project..Nashville_Housing AS A
JOIN Portfolio_Project..Nashville_Housing AS B
ON A.ParcelID = B.ParcelID
AND A.[UniqueID ] != B.[UniqueID ]
WHERE A.PropertyAddress IS NULL
;


------------------------------------------------------------------------------------------------------------------------------

--Splitting PropertyAddress into Individual Columns (Address, City) 

SELECT PropertyAddress
FROM Portfolio_Project..Nashville_Housing
;

SELECT
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1) AS Address,
SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress)) AS City
FROM Portfolio_Project..Nashville_Housing
;

ALTER TABLE Nashville_Housing
ADD Address nvarchar(255)
;

UPDATE Nashville_Housing
SET Address = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1)
;

ALTER TABLE Nashville_Housing
ADD City nvarchar(255)
;

UPDATE Nashville_Housing
SET City = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress))
;


--Splitting OwnerAddress into (OwnerAddress, OwnerCity, State)

SELECT OwnerAddress
FROM Portfolio_Project..Nashville_Housing
;


SELECT PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3),
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2),
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)
FROM Portfolio_Project..Nashville_Housing
;

ALTER TABLE Nashville_Housing
ADD OwnerSplitAddress nvarchar(255)
;

UPDATE Nashville_Housing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3)
;

ALTER TABLE Nashville_Housing
ADD OwnerSplitCity nvarchar(255)
;

UPDATE Nashville_Housing
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2)
;

ALTER TABLE Nashville_Housing
ADD OwnerSplitState nvarchar(255)
;

UPDATE Nashville_Housing
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)
;

----------------------------------------------------------------------------------------------------------------------------------------------

--Change Y and N to Yes and No in "Sold as Vacant" field

SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant)
FROM Portfolio_Project..Nashville_Housing
GROUP BY SoldAsVacant
ORDER BY 2
;

SELECT SoldAsVacant,
CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
	 WHEN SoldAsVacant = 'N' THEN 'No'
	 ELSE SoldAsVacant
	 END
FROM Portfolio_Project..Nashville_Housing
;

UPDATE Nashville_Housing
SET SoldAsVacant = CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
	 WHEN SoldAsVacant = 'N' THEN 'No'
	 ELSE SoldAsVacant
	 END
;

------------------------------------------------------------------------------------------------------------------------------------------------------

--Remove Duplicates

WITH Row_Num_CTE AS(
SELECT *,ROW_NUMBER() OVER (
		 PARTITION BY ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference
		 ORDER BY UniqueID) AS row_num
FROM Portfolio_Project..Nashville_Housing
--ORDER BY ParcelID
)

-- DELETE FROM Row_Num_CTE
--WHERE row_num > 1;

SELECT * FROM Row_Num_CTE
WHERE row_num > 1


-----------------------------------------------------------------------------------------------------------------------------------------------------------

--Delete Unused Columns

SELECT * FROM Portfolio_Project..Nashville_Housing
;

ALTER TABLE Portfolio_Project..Nashville_Housing
DROP COLUMN PropertyAddress, OwnerAddress, TaxDistrict, SaleDate
;