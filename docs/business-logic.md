# Business Logic

## Ingredient.status is "Computed Field"

```mermaid
classDiagram
    Enum <|-- IngredientStatus
    class IngredientStatus{
        IN_STOCK
        EXPIRED
        OUT_OF_STOCK
    }
```

```python
class IngredientRead(IngredientBase):
    ...

    @root_validator
    def set_status(cls, values):
        if values["expiry_date"] is None:
            values["status"] = IngredientStatus.OUT_OF_STOCK
        elif values["expiry_date"] <= date.today():
            values["status"] = IngredientStatus.EXPIRED
        else:
            values["status"] = IngredientStatus.IN_STOCK

        return values
```

!!! note

    Pydantic v2 allows to define genuine computed fields.
    Pydantic v1 does not support computed fields and the recommended workaround is to use `root_validator` for this requirement.
    Pydantic v1 is used in this project because SQLModel does not support Pydantic v2 yet.

## Ingredient.status is "State Machine"

```mermaid
stateDiagram-v2
    state "EXPIRED\nexpiry_date <= current_date" as EXPIRED
    state "OUT OF STOCK\nexpiry_date is None" as OUT_OF_STOCK
    state "IN STOCK\nexpiry_date > current_date" as IN_STOCK
    EXPIRED --> OUT_OF_STOCK : DELETE
    EXPIRED --> IN_STOCK : UPDATE\nexpiry_date > current_date
    IN_STOCK --> EXPIRED : OVER TIME
    IN_STOCK --> OUT_OF_STOCK : DELETE
    OUT_OF_STOCK --> IN_STOCK : UPDATE\nexpiry_date > current_date
```
