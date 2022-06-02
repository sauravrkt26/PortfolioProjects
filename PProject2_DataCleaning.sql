-- DATA CLEANING USING SQL

--Looking at the dataset

SELECT * 
FROM dbo.NashvilleHousing

--1) Standarizing Date

SELECT SaleDate, CONVERT(date, SaleDate)
FROM dbo.NashvilleHousing

ALTER TABLE NashvilleHousing
ALTER COLUMN SaleDate date

--2) Fixing the NULL values in PropertyAddress

SELECT *
FROM NashvilleHousing
WHERE PropertyAddress IS NULL
ORDER BY ParcelID

--When checking on the data, it seems like every ParcelID is linked to one address. Thus, we can use ParcelID to extract address and input where the PropertyAddress is NULL
--Joining tables to get address

SELECT a.ParcelID, b.ParcelID, a.PropertyAddress, b.PropertyAddress, ISNULL(b.PropertyAddress,a.PropertyAddress)
FROM NashvilleHousing a
JOIN NashvilleHousing b
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID ] != b.[UniqueID ]
WHERE b.PropertyAddress IS NULL
ORDER BY a.ParcelID

--Finally updating the table using the above

UPDATE b
SET b.PropertyAddress = ISNULL(b.PropertyAddress,a.PropertyAddress)
	FROM NashvilleHousing a
	JOIN NashvilleHousing b
		ON a.ParcelID = b.ParcelID
		AND a.[UniqueID ] != b.[UniqueID ]
	WHERE b.PropertyAddress IS NULL

--3) Breaking down address into individual columns (street add, city)
--Firstly for PropertyAddress

SELECT 
SUBSTRING(PropertyAddress,1,CHARINDEX(',',PropertyAddress,1) - 1) AS StreetAddress,
SUBSTRING(PropertyAddress,CHARINDEX(',',PropertyAddress,1) + 1,LEN(PropertyAddress)) AS City
FROM NashvilleHousing

ALTER TABLE NashvilleHousing
ADD SplitPropAddStreet NVARCHAR(255);

ALTER TABLE NashvilleHousing
ADD SplitPropAddCity NVARCHAR(100);

UPDATE NashvilleHousing
SET SplitPropAddStreet = SUBSTRING(PropertyAddress,1,CHARINDEX(',',PropertyAddress,1) - 1);

UPDATE NashvilleHousing
SET SplitPropAddCity = SUBSTRING(PropertyAddress,CHARINDEX(',',PropertyAddress,1) + 1,LEN(PropertyAddress));

--Doing the same for OwnerAddress using PARSENAME

SELECT 
PARSENAME(REPLACE(OwnerAddress,',','.'), 1),
PARSENAME(REPLACE(OwnerAddress,',','.'), 2),
PARSENAME(REPLACE(OwnerAddress,',','.'), 3)
FROM NashvilleHousing

ALTER TABLE dbo.NashvilleHousing
ADD SplitOwnerAddStreet NVARCHAR(255);

ALTER TABLE dbo.NashvilleHousing
ADD SplitOwnerAddCity NVARCHAR(100);

ALTER TABLE dbo.NashvilleHousing
ADD SplitOwnerAddState NVARCHAR(40);

UPDATE NashvilleHousing
SET SplitOwnerAddStreet = PARSENAME(REPLACE(OwnerAddress,',','.'), 3);

UPDATE NashvilleHousing
SET SplitOwnerAddCity = PARSENAME(REPLACE(OwnerAddress,',','.'), 2);

UPDATE NashvilleHousing
SET SplitOwnerAddState = PARSENAME(REPLACE(OwnerAddress,',','.'), 1);

--4) Organizing 'Sold as Vacant' column as it cointains Y,Yes, N and No

SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant)
FROM NashvilleHousing
GROUP BY SoldAsVacant

SELECT SoldAsVacant,
	CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
		 WHEN SoldAsVacant = 'N' THEN 'No'
		 ELSE SoldAsVacant
	END
FROM NashvilleHousing

UPDATE NashvilleHousing
SET SoldAsVacant = 
	CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
		 WHEN SoldAsVacant = 'N' THEN 'No'
		 ELSE SoldAsVacant
	END

--5) Removing duplicate rows

WITH RownumCTE 
AS
(
	SELECT *,
	ROW_NUMBER() OVER(PARTITION BY ParcelID, PropertyAddress, SaleDate, SalePrice, LegalReference, OwnerName ORDER BY ParcelID ) AS Row_num
	FROM NashvilleHousing
)

DELETE 
FROM RownumCTE
WHERE Row_num > 1

--6) Removing unused columns

ALTER TABLE NashvilleHousing
DROP COLUMN OwnerAddress
