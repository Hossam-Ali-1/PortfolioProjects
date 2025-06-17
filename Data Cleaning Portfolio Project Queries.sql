/*

Cleaning Data in SQL Queries 

*/

SELECT * FROM nashville_housing.nashvillehousing;

-- Standardize Date Format

SELECT SaleDate
FROM nashvillehousing;

Update nashvillehousing
Set SaleDate = STR_TO_DATE(SaleDate, '%M %d, %Y');


-- Populate Property Address data

SELECT * From nashvillehousing
-- Where PropertyAddress is null
ORDER BY ParcelID;

SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress,
ifnull(a.PropertyAddress, b.PropertyAddress)
FROM nashvillehousing AS a
JOIN nashvillehousing AS b
	on a.ParcelID = b.ParcelID
	And a.UniqueID <> b.UniqueID
Where a.PropertyAddress is null;


UPDATE nashvillehousing AS a
JOIN nashvillehousing AS b 
    ON a.ParcelID = b.ParcelID
    AND a.UniqueID <> b.UniqueID
SET a.PropertyAddress = IFNULL(a.PropertyAddress, b.PropertyAddress)
WHERE a.PropertyAddress IS NULL;


-- Breaking out Address into Individual Columns (Address, City, State)

SELECT PropertyAddress From nashvillehousing;
-- Where PropertyAddress is null
-- order by PacreclID

SELECT SUBSTRING(PropertyAddress, 1, LOCATE(',' , PropertyAddress) -1) AS Address,
SUBSTRING(PropertyAddress, LOCATE(',' , PropertyAddress) +1 ) AS City
From nashvillehousing;

ALTER TABLE nashvillehousing
Add PropertySplitAddress VARCHAR(255);

Update nashvillehousing
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, LOCATE(',' , PropertyAddress) -1);

ALTER TABLE nashvillehousing
Add PropertySplitCity VARCHAR(255);

Update nashvillehousing
SET PropertySplitCity = SUBSTRING(PropertyAddress, LOCATE(',' , PropertyAddress) +1 );

SELECT * FROM nashvillehousing;

SELECT OwnerAddress FROM nashvillehousing;

SELECT
  SUBSTRING_INDEX(OwnerAddress, ',', 1),     -- أول جزء
  SUBSTRING_INDEX(SUBSTRING_INDEX(OwnerAddress, ',', 2), ',', -1), -- ثاني جزء
  SUBSTRING_INDEX(OwnerAddress, ',', -1)        -- آخر جزء
FROM nashvillehousing;

ALTER TABLE nashvillehousing
Add OwnerSplitAddress VARCHAR(255); 

UPDATE nashvillehousing
SET OwnerSplitAddress = SUBSTRING_INDEX(OwnerAddress, ',', 1);

ALTER TABLE nashvillehousing
Add OwnerSplitCity VARCHAR(255); 

UPDATE nashvillehousing
SET OwnerSplitCity = SUBSTRING_INDEX(SUBSTRING_INDEX(OwnerAddress, ',', 2), ',', -1);

ALTER TABLE nashvillehousing
Add OwnerSplitState VARCHAR(255); 

UPDATE nashvillehousing
SET OwnerSplitState = SUBSTRING_INDEX(OwnerAddress, ',', -1);

SELECT * FROM nashvillehousing;


-- Change Y and N to Yes and No in "Sold as Vacant" field

SELECT DISTINCT(SoldAsVacant), Count(SoldAsVacant)
FROM nashvillehousing
Group BY SoldAsVacant
order by 2;

SELECT SoldAsVacant,
CASE
	when SoldAsVacant = 'Y' THEN 'Yes'
    when SoldAsVacant = 'N' THEN 'No'
    ELSE SoldAsVacant
END
FROM nashvillehousing;


UPDATE nashvillehousing
SET SoldAsVacant = CASE
	when SoldAsVacant = 'Y' THEN 'Yes'
    when SoldAsVacant = 'N' THEN 'No'
    ELSE SoldAsVacant
END;

SELECT * FROM nashvillehousing;

-- Check for Duplicates

WITH RowNumCTE AS(
SELECT *,
	ROW_NUMBER() OVER(
	PARTITION BY ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference
                 ORDER BY UniqueID
    ) AS row_num
    
From nashvillehousing
-- order by ParcelID
)

SELECT * From RowNumCTE
where row_num > 1
order by PropertyAddress;

-- Backup before deleting
CREATE TABLE nashvillehousing_backup AS 
SELECT * FROM nashvillehousing;

-- Remove Duplicates

DELETE FROM nashvillehousing
WHERE UniqueID IN (
  SELECT UniqueID FROM (
    SELECT UniqueID,
           ROW_NUMBER() OVER(
             PARTITION BY ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference
             ORDER BY UniqueID
           ) AS row_num
    FROM nashvillehousing
  ) AS temp
  WHERE row_num > 1
);

-- Delete Unused Columns

SELECT * From nashvillehousing;

ALTER TABLE nashvillehousing
DROP COLUMN OwnerAddress,
DROP COLUMN TaxDistrict,
DROP COLUMN PropertyAddress,
DROP COLUMN SaleDate;

SELECT * From nashvillehousing;
