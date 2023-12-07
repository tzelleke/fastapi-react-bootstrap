# API

## DRY Pagination

### Definition

```python
class PaginationParams:
    def __init__(
        self,
        offset: Annotated[
            int | None,
            Query(
                ge=1,
                description="Pagination: defines the number of records to skip before returning the result.",  # noqa: E501
            ),
        ] = None,
        limit: Annotated[
            int | None,
            Query(
                ge=1,
                description="Pagination: defines the number of records to return in the result.",  # noqa: E501
            ),
        ] = None,
    ) -> None:
        self.offset = offset
        self.limit = limit

    def __call__(self, statement: Any) -> Any:
        if self.offset:
            statement = statement.offset(self.offset)
        if self.limit:
            statement = statement.limit(self.limit)

        return statement


TPaginationParams = Annotated[dict[str, int], Depends(PaginationParams)]
```

### Usage

```python
@router.get("")
async def read_many(
    *,
    only_available: bool = False,
    paginator: TPaginationParams,
    session: Annotated[Session, Depends(get_session)],
) -> list[CocktailRead]:
    ...

    return session.exec(paginator(statement)).all()
```

```python
@router.get("")
async def read_many(
    *,
    paginator: TPaginationParams,
    session: Annotated[Session, Depends(get_session)],
) -> list[IngredientRead]:
    return session.exec(paginator(select(Ingredient))).all()
```
