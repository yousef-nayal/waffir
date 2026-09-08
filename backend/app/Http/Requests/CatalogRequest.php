<?php
namespace App\Http\Requests;
class CatalogRequest extends ApiRequest
{
    public function rules() { return ['name'=>'required|string|max:255','slug'=>'nullable|string|max:255','logo_url'=>'nullable|url|max:2048','description'=>'nullable|string','image_url'=>'nullable|url|max:2048','symbol'=>'nullable|string|max:20','is_active'=>'sometimes|boolean']; }
}
